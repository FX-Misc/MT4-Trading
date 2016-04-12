#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property strict

#import "stdlib.ex4" 
string ErrorDescription(int error_code); 
#import

struct OrderStruct {
    int      ticket;
    int      orderType;
    datetime openTime;
    string   symbol;
    double   lots;
    double   openPrice;
    double   takeProfit;
    double   stopLoss;
    datetime closeTime;
    double   closePrice;
    double   profit;
    double   swap;
    datetime expiredTime;
    string   comment;
    int      magicNumber;
};


//組合錯誤訊息
string CompileErrorMessage(int errorCode) {
    return (string)errorCode + " - " + ErrorDescription(errorCode);
}


//偵測是否有新的 K 棒產生
bool HasNewBar() {
    static datetime lastBarOpenTime;
    datetime currentBarOpenTime = Time[0];

    if(lastBarOpenTime != currentBarOpenTime) {
        lastBarOpenTime = currentBarOpenTime;
        return true;
    } else {
        return false;
    }
}


//以市價結清指定的倉單
bool CloseMarketOrders(OrderStruct& orders[]) {
    if(ArraySize(orders) == 0)  return true;
    
    double closePrice;

    for(int i = 0; i < ArraySize(orders); i++) {
        closePrice = (orders[i].orderType == OP_BUY)? Bid : Ask;
        if(!OrderClose(orders[i].ticket, orders[i].lots, closePrice, 0)) {
            Print("Close ticket ", orders[i].ticket, " failed: ", CompileErrorMessage(GetLastError()));
            return false;
        }
    }
    return true;
}


//刪除預掛單
bool DeletePendingOrders(OrderStruct& orders[]) {
    for(int i = 0; i < ArraySize(orders); i++) {
        if(!OrderDelete(orders[i].ticket))
            Print("Delete pending ticket ", orders[i].ticket, " failed: ", CompileErrorMessage(GetLastError()));
            return false;
    }    
    return true;
}


//刪除預掛單
bool DeletePendingOrders(int& tickets[]) {
    for(int i = 0; i < ArraySize(tickets); i++) {
        if(!OrderDelete(tickets[i])) {
            Print("Delete pending ticket ", tickets[i], " failed: ", CompileErrorMessage(GetLastError()));
            return false;
        }    
    }    
    return true;
}


//取得指定類型的倉單編號
bool CollectOrders(string symbol, int orderType, int magicNumber, int& tickets[]) {
    ArrayFree(tickets);
    int idx = 0;

    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == symbol && OrderType() == orderType && OrderMagicNumber() == magicNumber) {
                ArrayResize(tickets, ArraySize(tickets) + 1, 25);
                tickets[ArraySize(tickets) - 1] = OrderTicket();
            }
        } else {
            Print("Select order failed: ", CompileErrorMessage(GetLastError()));
            return false;
        }
    }
    
    return true;
}


//取得指定類型的倉單明細
bool CollectOrders(string symbol, int orderType, int magicNumber, OrderStruct& orders[]) {
    ArrayFree(orders);
    int idx = 0;
    
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == symbol && OrderType() == orderType && OrderMagicNumber() == magicNumber) {
                AddTicketToPosition(OrderTicket(), orders);
            }
        } else {
            Print("Select order failed: ", CompileErrorMessage(GetLastError()));
            return false;
        }
    }
    return true;
}


//取得指定類型的歷史交易明細
bool CollectHistoryOrders(string symbol, int orderType, int magicNumber, OrderStruct& orders[]) {
    ArrayFree(orders);
    int idx = 0;
    
    for(int i = 0; i < OrdersHistoryTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            if(OrderSymbol() == symbol && OrderType() == orderType && OrderMagicNumber() == magicNumber) {
                AddTicketToPosition(OrderTicket(), orders);
            }
        } else {
            Print("Select order failed: ", CompileErrorMessage(GetLastError()));
            return false;
        }
    }
    return true;
}


//將指定交易單號資訊加入交易單陣列
bool AddTicketToPosition(int ticket, OrderStruct& orders[]) {
    if(OrderSelect(ticket, SELECT_BY_TICKET)) {
        ArrayResize(orders, ArraySize(orders) + 1, 25);
        int idx = ArraySize(orders) - 1;
        orders[idx].ticket = OrderTicket();
        orders[idx].orderType = OrderType();
        orders[idx].openTime = OrderOpenTime();
        orders[idx].symbol = OrderSymbol();
        orders[idx].lots = OrderLots();
        orders[idx].openPrice = OrderOpenPrice();
        orders[idx].takeProfit = OrderTakeProfit();
        orders[idx].stopLoss = OrderStopLoss();
        orders[idx].closeTime = OrderCloseTime();
        orders[idx].closePrice = OrderClosePrice();
        orders[idx].profit = OrderProfit();
        orders[idx].expiredTime = OrderExpiration();
        orders[idx].swap = OrderSwap();
        orders[idx].comment = OrderComment();
        orders[idx].magicNumber = OrderMagicNumber();
    
        return true;
            
    } else {
        Print("Select ticket ", ticket, " failed: ", CompileErrorMessage(GetLastError()));
        return false;
    }
}


//取得時區的代碼
string GetTimeFrameString(int period) {
    switch(period) {
        case     1: return "M1";
        case     5: return "M5";
        case    15: return "M15";
        case    30: return "M30";
        case    60: return "H1";
        case   240: return "H4";
        case  1440: return "D1";
        case 10080: return "W1";
        case 43200: return "MN1";
        default   : return "";
    }
}


//檢查是否處於可交易時間內
bool IsTradeTime(string weekDays, int startHour, int endHour) {
    if(weekDays == "")  return false;
    
    MqlDateTime dt;
    TimeToStruct(TimeLocal(), dt);

    //判斷星期幾
    if(StringFind(weekDays, (string)dt.day_of_week) < 0)  return false;
    
    //起訖時段未跨日
    if(startHour <= endHour) {
        if(dt.hour >= startHour && dt.hour <= endHour)  return true;
    }
    
    //起訖時段跨日
    if(startHour > endHour) {
        if((dt.hour >= 0 && dt.hour <= endHour) || (dt.hour >= startHour && dt.hour <= 23))  return true;
    }

    return false;
}


//檢查是否處於可交易時間內
bool IsTradeTime(string startTime, string endTime) {
    if(startTime == "" || endTime == "")  return false;
    
    datetime st = StringToTime(TimeToString(TimeLocal(), TIME_DATE) + " " + startTime);
    datetime et = StringToTime(TimeToString(TimeLocal(), TIME_DATE) + " " + endTime);
    
    if(st <= TimeLocal() && TimeLocal() <= et)
        return true;
    else
        return false;
}

//*** 鱷魚線趨勢判斷相關函數 *********
//趨勢線方向
const int TREND_NONE    = 0;   //無明確趨勢
const int TREND_LONG    = 1;   //看多趨勢
const int TREND_SHORT   = -1;  //看空趨勢
const int ALLIGATOR_GAP = 5;   //鱷魚線之間的間隙, 須大於此數才確認為趨勢


//以 M30, D1 鱷魚線判斷目前趨勢
int GetTrendByAlligator() {
    int trendH1 = AlligatorTrend(PERIOD_M30, -3);
    int trendD1 = AlligatorTrend(PERIOD_D1, -3);
    
    if(trendH1 == trendD1)  return trendH1;
    else  return TREND_NONE;
}


//取得鱷魚線的值(以 Median 價格計)
double GetAlligator(int timeFrame, int lineMode, int shift, ENUM_APPLIED_PRICE priceType = PRICE_MEDIAN) {
    return iAlligator(Symbol(), timeFrame, 13, 8, 8, 5, 5, 3, MODE_SMMA, priceType, lineMode, shift);
}


//判斷一組鱷魚線是否呈現趨勢
int AlligatorTrend(int timeFrame, int shift = 0, ENUM_APPLIED_PRICE priceType = PRICE_MEDIAN) {
    double lips = GetAlligator(timeFrame, MODE_GATORLIPS, shift, priceType);
    double teeth = GetAlligator(timeFrame, MODE_GATORTEETH, shift, priceType);
    double jaw = GetAlligator(timeFrame, MODE_GATORJAW, shift, priceType);
    
    double diff_lips_teeth = MathAbs(lips - teeth) * MathPow(10, Digits);
    double diff_jaw_teeth = MathAbs(jaw - teeth) * MathPow(10, Digits);
    
    PrintFormat("timeframe: %s; shift: %d; lips = %.5f; teeth = %.5f; jaw = %.5f; diff_lips_teeth: %.0f; diff_jaw_teeth: %.0f", GetTimeFrameString(timeFrame), shift, lips, teeth, jaw, diff_lips_teeth, diff_jaw_teeth);
    
    if(lips > teeth && teeth > jaw && diff_lips_teeth > ALLIGATOR_GAP && diff_jaw_teeth > ALLIGATOR_GAP) {
        PrintFormat("Timeframe %s, shift %d is a LONG trend.", GetTimeFrameString(timeFrame), shift);
        return TREND_LONG;
    }
    
    if(jaw > teeth && teeth > lips && diff_lips_teeth > ALLIGATOR_GAP && diff_jaw_teeth > ALLIGATOR_GAP) {
        PrintFormat("Timeframe %s, shift %d is a SHORT trend.", GetTimeFrameString(timeFrame), shift);
        return TREND_SHORT;
    }
    
    PrintFormat("Timeframe %s, shift %d has NO trend.", GetTimeFrameString(timeFrame), shift);
    return TREND_NONE;
}
//*** 鱷魚線趨勢判斷相關函數 *********


//*** 進場判斷相關函數 *********
//進場訊號
const int SIGNAL_NONE = 0;    //無進場訊號
const int SIGNAL_BUY  = 1;    //BUY 進場訊號
const int SIGNAL_SELL = -1;   //SELL 進場訊號


//取得包寧傑通道的值
double GetBollingerBand(int timeFrame, double deviation, int lineMode, int shift, ENUM_APPLIED_PRICE priceType = PRICE_CLOSE) {
    return iBands(Symbol(), timeFrame, 20, deviation, 0, priceType, lineMode, shift);
}


//以包寧傑通道判斷指定 K 棒是否有進場訊號
//最近二根完整 K 棒收在 BB1 之外, 且再向前二根收在 BB1 之內, 判斷為進場訊號
int GetSignalByDBB(int barIndex) {
    //check buy signal
    if(Close[barIndex]     > GetBollingerBand(Period(), 1, MODE_UPPER, barIndex, PRICE_CLOSE) &&
       Close[barIndex + 1] > GetBollingerBand(Period(), 1, MODE_UPPER, barIndex + 1, PRICE_CLOSE) &&
       Close[barIndex + 2] < GetBollingerBand(Period(), 1, MODE_UPPER, barIndex + 2, PRICE_CLOSE) &&
       Close[barIndex + 3] < GetBollingerBand(Period(), 1, MODE_UPPER, barIndex + 3, PRICE_CLOSE)) {
        return SIGNAL_BUY;
    }

    //check sell signal
    if(Close[barIndex]     < GetBollingerBand(Period(), 1, MODE_LOWER, barIndex, PRICE_CLOSE) &&
       Close[barIndex + 1] < GetBollingerBand(Period(), 1, MODE_LOWER, barIndex + 1, PRICE_CLOSE) &&
       Close[barIndex + 2] > GetBollingerBand(Period(), 1, MODE_LOWER, barIndex + 2, PRICE_CLOSE) &&
       Close[barIndex + 3] > GetBollingerBand(Period(), 1, MODE_LOWER, barIndex + 3, PRICE_CLOSE)) {
        return SIGNAL_SELL;
    }
    
    return SIGNAL_NONE;
}


//以鱷魚線判斷指定 K 棒是否有進場訊號
//最近一根完整 K 棒收在唇線之外, 向前二根均持續過高/破低, 且鱷魚開口成形則判斷為進場訊號
int GetSignalByAlligator(int barIndex) {
    int trend = AlligatorTrend(Period(), barIndex - 4);

    //check buy signal
    if(trend == TREND_LONG &&
       Close[barIndex] > GetAlligator(Period(), MODE_GATORLIPS, barIndex, PRICE_CLOSE) &&
       Close[barIndex] > Close[barIndex + 1] &&
       Close[barIndex + 1] > Close[barIndex + 2]) {
        return SIGNAL_BUY;
    }

    //check sell signal
    if(trend == TREND_SHORT &&
       Close[barIndex] < GetAlligator(Period(), MODE_GATORLIPS, barIndex, PRICE_CLOSE) &&
       Close[barIndex] < Close[barIndex + 1] &&
       Close[barIndex + 1] < Close[barIndex + 2]) {
        return SIGNAL_SELL;
    }
        
    return SIGNAL_NONE;
}
//*** 進場判斷相關函數 *********


//送出交易單
int SendOrder(string symbol, int orderType, double orderPrice, double orderLots, string comment, int magicNumber, double takeProfit = 0, double stopLoss = 0) {
    const int SLIPPAGE = 0;  //交易滑點容許值
    color arrowColor = (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT)? clrBlue : clrRed;
    
    int ticket = OrderSend(symbol, orderType, orderLots, orderPrice, SLIPPAGE, stopLoss, takeProfit, comment, magicNumber, 0, arrowColor);
    
    if(ticket < 0) {
        Print("Send order failed: ", CompileErrorMessage(GetLastError()));
    }
    return ticket;
}


//修改交易單內容
bool ModifyOrder(int ticket, int orderType, double price, double stopLoss, double takeProfit) {
    color arrowColor = (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT)? clrBlue : clrRed;
    if(!OrderModify(ticket, price, stopLoss, takeProfit, 0, arrowColor)) {
        Print("Modify ticket ", ticket, " failed: ", CompileErrorMessage(GetLastError()));
        return false;
    }
    return true;
}


//將價格轉換為整數, 方便比較, e.g 1.12345 --> 112345
int PriceToInteger(double price) {
    return (int)MathRound(price * MathPow(10, Digits));
}


//將整數轉換為價格, 方便交易, e.g 112345 --> 1.12345
double IntegerToPrice(int price) {
    return NormalizeDouble(price * Point, Digits);
}


//檢查目前浮虧比率是否超過停損比率
bool IsReachStopLossPercent(double stopLossPercent) {
    if(stopLossPercent <= 0)  return false;

    double currentLossPercent = (AccountProfit() / AccountBalance()) * 100;
    if(currentLossPercent <= -stopLossPercent) {
        PrintFormat("Current loss percent %.2f exceeds target percent %.2f", MathAbs(currentLossPercent), stopLossPercent);
        return true;
    }
    else  return false;
}


//檢查目前浮虧金額是否超過停損金額
bool IsReachStopLossAmount(double stopLossAmount) {
    if(stopLossAmount <= 0)  return false;

    double currentLossAmount = AccountProfit();
    if(currentLossAmount <= -stopLossAmount) {
        PrintFormat("Current loss amount %.2f exceeds target amount %.2f", MathAbs(currentLossAmount), stopLossAmount);
        return true;
    }
    else  return false;
}


//Read data from file
string ReadData(string fileName, string key) {
    int inFile = FileOpen(fileName, FILE_COMMON | FILE_READ | FILE_TXT, ',', CP_UTF8);
    if(inFile < 0) {
        Print("ERROR: Unable to open file. ", CompileErrorMessage(GetLastError()));
        return "";
    }
    
    string tmp = FileReadString(inFile);
    FileClose(inFile);

    string kv[];
    if(StringSplit(tmp, StringGetCharacter("=", 0), kv) != 2) {
        Print("ERROR: Unable split string. ", CompileErrorMessage(GetLastError()));
        return "";
    }
    
    if(kv[0] == key)
        return kv[1];
    else
        return "";

    return tmp;
}


//Write data to file
bool WriteData(string fileName, string key, string value) {
    int outFile = FileOpen(fileName, FILE_COMMON | FILE_WRITE | FILE_TXT, ',', CP_UTF8);
    if(outFile < 0) {
        Print("ERROR: Unable to open file. ", CompileErrorMessage(GetLastError()));
        return false;
    }

    FileWrite(outFile, key + "=" + value);

    FileFlush(outFile);
    FileClose(outFile);
    
    return true;
}


//Export history orders to CSV file
bool ExportTradeHistory(string symbol, string closeDateStart, string closeDateEnd, int magicNumber) {
    string startDate = "";
    string endDate = "";
    
    //如果起訖都不輸入, 就預設為本地系統日的前一日
    if(closeDateStart == "" && closeDateEnd == "") {
        startDate = TimeToString(TimeLocal() - 24 * 60 * 60, TIME_DATE);
        endDate = startDate;
    }

    //如果只輸入起日, 訖日設為當日
    if(closeDateStart != "" && closeDateEnd == "") {
        startDate = closeDateStart;
        endDate = TimeToString(TimeLocal(), TIME_DATE);
    }
    
    //如果只輸入訖日, 起日設為 2010.01.01
    if(closeDateStart == "" && closeDateEnd != "") {
        startDate = "2010.01.01";
        endDate = closeDateEnd;
    }
    
    int histOrders = OrdersHistoryTotal();
    Print("Total history orders: ", histOrders, ", Date to parse: ", startDate, " ~ ", endDate);

    string fileName = (string)AccountNumber() + ".csv";
    int outFile = FileOpen(fileName, FILE_COMMON|FILE_WRITE|FILE_CSV, ',', CP_UTF8);
    if(outFile < 0) {
        Print("ERROR: Unable to open file: ", CompileErrorMessage(GetLastError()));
        return false;
    }
    
    FileWrite(outFile, "Account", "Ticket", "Symbol", "OrderType", "OpenTime", "OpenPrice", "CloseTime", "ClosePrice", "Lots", "Profit", "TakeProfit", "StopLoss", "Swap", "Commission", "Comment", "MagicNumber");
    
    double buyLots = 0;
    double sellLots = 0;
    double netProfit = 0;
    for(int i = 0; i < histOrders; i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            if(OrderSymbol() == symbol &&
               OrderMagicNumber() == magicNumber &&
               TimeToString(OrderCloseTime(), TIME_DATE) >= startDate &&
               TimeToString(OrderCloseTime(), TIME_DATE) <= endDate &&
               OrderType() <= 1 ) {  // 0: buy, 1:sell

                FileWrite(outFile, AccountNumber(), OrderTicket(), OrderSymbol(), OrderType(), 
                    OrderOpenTime(), OrderOpenPrice(), OrderCloseTime(), OrderClosePrice(), 
                    OrderLots(), OrderProfit(), OrderTakeProfit(), OrderStopLoss(), OrderSwap(), OrderCommission(), 
                    OrderComment(), OrderMagicNumber());

                if(OrderType() == 0)  buyLots += OrderLots();
                else  sellLots += OrderLots();
                netProfit += (OrderProfit() + OrderCommission() + OrderSwap());
            }
        } else {
            Print("ERROR: Failed to get order: ", CompileErrorMessage(GetLastError()));
            return false;
        }
    }

    FileFlush(outFile);
    FileClose(outFile);
    
    PrintFormat("Transaction summary between %s and %s: Buy %.2f, Sell %.2f, Net profit %.2f", startDate, endDate, buyLots, sellLots, netProfit);

    return true;
}
