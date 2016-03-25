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
    if(ArraySize(orders) == 0) return true;
    
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
    MqlDateTime dt;
    TimeToStruct(TimeLocal(), dt);

    //判斷星期幾
    if(StringFind(weekDays, (string)dt.day_of_week) < 0) return false;
    
    //起訖時段未跨日
    if(startHour <= endHour) {
        if(dt.hour >= startHour && dt.hour <= endHour) return true;
    }
    
    //起訖時段跨日
    if(startHour > endHour) {
        if((dt.hour >= 0 && dt.hour <= endHour) || (dt.hour >= startHour && dt.hour <= 23)) return true;
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

//趨勢線方向
const int TREND_NONE    = 0;   //無明確趨勢
const int TREND_LONG    = 1;   //看多趨勢
const int TREND_SHORT   = -1;  //看空趨勢
const int ALLIGATOR_GAP = 5;   //鱷魚線之間的間隙, 須大於此數才確認為趨勢


//以 M30, D1 鱷魚線判斷目前趨勢
int GetTrendByAlligator() {
    int trendH1 = AlligatorTrend(PERIOD_M30, -3);
    int trendD1 = AlligatorTrend(PERIOD_D1, -3);
    
    if(trendH1 == trendD1) return trendH1;
    else return TREND_NONE;
}


//取得鱷魚線的值
double GetAlligator(int timeFrame, int lineMode, int shift) {
    return iAlligator(Symbol(), timeFrame, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, lineMode, shift);
}


//判斷一組鱷魚線是否呈現趨勢
int AlligatorTrend(int timeFrame, int shift = 0) {
    double lips = GetAlligator(timeFrame, MODE_GATORLIPS, shift);
    double teeth = GetAlligator(timeFrame, MODE_GATORTEETH, shift);
    double jaw = GetAlligator(timeFrame, MODE_GATORJAW, shift);
    
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