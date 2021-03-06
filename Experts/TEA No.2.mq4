#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.27"
#property description "提姆茶２號"
#property description "以鱷魚線判斷短期走勢，進行雙向佈局"
#property description "走勢相反時，加碼馬丁單降低持倉成本，等待成交"
#property strict
#include <TEA.mqh>

//使用者輸入參數
input string CUSTOM_COMMENT                 = "【提姆茶２號】";    //畫面註解
input string BREAK_LINE_1                   = "＝＝＝＝＝";        //＝ [ 進場控制 ] ＝＝＝＝＝＝
input string TRADE_DAYS                     = "123456";            //操作日 (星期123456)
input int    TRADE_START_HOUR               = 0;                   //操作開始時間
input int    TRADE_END_HOUR                 = 23;                  //操作結束時間
input bool   USE_TREND_FOR_FIRST_ORDER      = true;                //起始單趨勢判斷
input bool   USE_TREND_FOR_MARTIN_ORDER     = true;                //馬丁單趨勢判斷
input bool   USE_MULTI_CHARTS               = false;               //多圖表模式
input string BREAK_LINE_2                   = "＝＝＝＝＝";        //＝ [ 風險管理 ] ＝＝＝＝＝＝
input bool   ENABLE_CLEAN_UP_MODE           = false;               //開啟清倉模式
input bool   ENABLE_KD_PROTECTION           = true;                //禁止在 KD 鈍化區下反向單
input double TAKE_PROFIT_AMOUNT             = 0;                   //停利金額 (0: 關閉)
input double STOP_LOSS_AMOUNT               = 0;                   //停損金額 (0: 關閉)
input bool   STOP_TRADE_AFTER_STOP_LOSS     = true;                //停損後暫停下單
input string BREAK_LINE_3                   = "＝＝＝＝＝";        //＝ [ BUY 馬丁參數 ] ＝＝＝＝＝＝
input double BUY_INITIAL_LOTS               = 0.01;                //BUY 起始手數
input int    BUY_INITIAL_TAKE_PROFIT        = 100;                 //BUY 起始獲利點數
input double BUY_MARTIN_MULTIPLIER          = 2;                   //BUY 馬丁比例
input int    BUY_MARTIN_DISTANCE            = 180;                 //BUY 馬丁點距
input int    BUY_MARTIN_DISTANCE_INCREMENT  = 0;                   //BUY 馬丁點距增減數
input int    BUY_MARTIN_MAX_ORDERS          = 5;                   //BUY 馬丁最大張數
input int    BUY_MARTIN_TAKE_PROFIT         = 60;                  //BUY 馬丁獲利點數
input string BREAK_LINE_4                   = "＝＝＝＝＝";        //＝ [ SELL 馬丁參數 ] ＝＝＝＝＝＝
input bool   REPLICATE_BUY_MARTIN_PARAM     = true;                //與 BUY 馬丁參數相同
input double SELL_INITIAL_LOTS              = 0.01;                //SELL 起始手數
input int    SELL_INITIAL_TAKE_PROFIT       = 100;                 //SELL 起始獲利點數
input double SELL_MARTIN_MULTIPLIER         = 2;                   //SELL 馬丁比例
input int    SELL_MARTIN_DISTANCE           = 180;                 //SELL 馬丁點距
input int    SELL_MARTIN_DISTANCE_INCREMENT = 0;                   //SELL 馬丁點距增減數
input int    SELL_MARTIN_MAX_ORDERS         = 5;                   //SELL 馬丁最大張數
input int    SELL_MARTIN_TAKE_PROFIT        = 60;                  //SELL 馬丁獲利點數
input string BREAK_LINE_5                   = "＝＝＝＝＝";        //＝ [ 單獨出場 ] ＝＝＝＝＝＝
input bool   BUY_USE_SAPERATED_TAKE_PROFIT  = false;               //BUY 開關
input int    BUY_TAKE_PROFIT                = 100;                 //BUY 獲利點數
input bool   SELL_USE_SAPERATED_TAKE_PROFIT = false;               //SELL 開關
input int    SELL_TAKE_PROFIT               = 100;                 //SELL 獲利點數
input string BREAK_LINE_6                   = "＝＝＝＝＝";        //＝ [ 交易紀錄 ] ＝＝＝＝＝＝
input bool   EXPORT_TXN_LOG                 = true;                //是否每日匯出交易紀錄


//EA 相關
const int    MAGIC_NUMBER         = 930214;
const string ORDER_COMMENT_PREFIX = "TEA2_";    //交易單說明前置字串


//資訊顯示用的 Label 物件名稱
const string LBL_COMMENT       = "lblComment";
const string LBL_TRADE_ENV     = "lblTradEvn";
const string LBL_PRICE         = "lblPrice";
const string LBL_TRENDING_TEXT = "lblTrendingText";
const string LBL_TREND_LONG    = "lblTrendingBuy";
const string LBL_TREND_SHORT   = "lblTrendingSell";
const string LBL_SAR_INDICATOR = "lblSarIndicator";
const string LBL_SPREAD        = "lblSpread";
const string LBL_SERVER_TIME   = "lblServerTime";
const string LBL_LOCAL_TIME    = "lblLocalTime";
const string LBL_TRADE_TIME    = "lblTradeTime";
const string LBL_STOP_TRADE    = "lblStopTrade";
const string LBL_BUY_PARAM     = "lblBuyParam";
const string LBL_SELL_PARAM    = "lblSellParam";
const string LBL_BASIC_PARAM   = "lblBasicParam";
const string LBL_MAX_LOSS_AMT  = "lblMaxLossAmt";
const string LBL_CLEANUP_TEXT  = "lblCleanUpMode";
const string LBL_POSITION_DAYS = "lblPositionDays";
const string ARROW_UP          = "↑";
const string ARROW_DOWN        = "↓";
const string ARROW_NONE        = "　";
const string CIRCLE            = "●";
const string TRADE_TIME_MSG    = "茶棧已打烊，明日請早！";
const string STOP_TRADE_MSG    = "已達停損標準，茶棧暫停營業！";


//MT4全域變數
const string GV_STOP_TRADE     = "IS_STOP_TRADING";


//全域變數
static bool        gs_isTradeTime    = false;
static bool        gs_stopTrading    = false;
static string      gs_symbol         = Symbol();
static long        gs_chartId        = 0;
static int         gs_currentTrend   = TREND_NONE;
static string      gs_fileName       = "TEA2_" + (string)AccountNumber() + ".txt";
static double      gs_maxLossAmt     = 0;
static string      gs_maxLossAmtKey  = "MaxLossAmount";
static string      gs_lastExportDate = "";
static OrderStruct gs_buyPosition[];
static OrderStruct gs_sellPosition[];

static double      gs_buyInitialLots;
static int         gs_buyInitialTakeProfit;
static double      gs_buyMartinMultiplier;
static int         gs_buyMartinDistance;
static int         gs_buyMartinDistanceIncrement;
static int         gs_buyMartinMaxOrders;
static int         gs_buyMartinTakeProfit;
static double      gs_sellInitialLots;
static int         gs_sellInitialTakeProfit;
static double      gs_sellMartinMultiplier;
static int         gs_sellMartinDistance;
static int         gs_sellMartinDistanceIncrement;
static int         gs_sellMartinMaxOrders;
static int         gs_sellMartinTakeProfit;


int OnInit() {
    Print("Initializing ...");

    gs_symbol = Symbol();
    gs_chartId = ChartID();
    gs_currentTrend = GetTrendByAlligator(PRICE_CLOSE);
    gs_isTradeTime = IsTradeTime(TRADE_DAYS, TRADE_START_HOUR, TRADE_END_HOUR);
    GlobalVariableSet(GV_STOP_TRADE, 0);   //set stop trading GV to false
    gs_stopTrading = (bool)GlobalVariableGet(GV_STOP_TRADE);
    gs_lastExportDate = "";

    gs_buyInitialLots             = BUY_INITIAL_LOTS;
    gs_buyInitialTakeProfit       = BUY_INITIAL_TAKE_PROFIT;
    gs_buyMartinMultiplier        = BUY_MARTIN_MULTIPLIER;
    gs_buyMartinDistance          = BUY_MARTIN_DISTANCE;
    gs_buyMartinDistanceIncrement = BUY_MARTIN_DISTANCE_INCREMENT;
    gs_buyMartinMaxOrders         = BUY_MARTIN_MAX_ORDERS;
    gs_buyMartinTakeProfit        = BUY_MARTIN_TAKE_PROFIT;
    
    gs_sellInitialLots             = REPLICATE_BUY_MARTIN_PARAM? BUY_INITIAL_LOTS              : SELL_INITIAL_LOTS;
    gs_sellInitialTakeProfit       = REPLICATE_BUY_MARTIN_PARAM? BUY_INITIAL_TAKE_PROFIT       : SELL_INITIAL_TAKE_PROFIT;
    gs_sellMartinMultiplier        = REPLICATE_BUY_MARTIN_PARAM? BUY_MARTIN_MULTIPLIER         : SELL_MARTIN_MULTIPLIER;
    gs_sellMartinDistance          = REPLICATE_BUY_MARTIN_PARAM? BUY_MARTIN_DISTANCE           : SELL_MARTIN_DISTANCE;
    gs_sellMartinDistanceIncrement = REPLICATE_BUY_MARTIN_PARAM? BUY_MARTIN_DISTANCE_INCREMENT : SELL_MARTIN_DISTANCE_INCREMENT;
    gs_sellMartinMaxOrders         = REPLICATE_BUY_MARTIN_PARAM? BUY_MARTIN_MAX_ORDERS         : SELL_MARTIN_MAX_ORDERS;
    gs_sellMartinTakeProfit        = REPLICATE_BUY_MARTIN_PARAM? BUY_MARTIN_TAKE_PROFIT        : SELL_MARTIN_TAKE_PROFIT;

    string tmp = ReadData(gs_fileName, gs_maxLossAmtKey);
    if(tmp != "")  gs_maxLossAmt = (double)tmp * -1;

    CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
    CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);
    Print("Current position: BUY = ", ArraySize(gs_buyPosition), ", SELL = ", ArraySize(gs_sellPosition));

    //set take profit
    SetTakeProfit(gs_buyPosition, OP_BUY);
    SetTakeProfit(gs_sellPosition, OP_SELL);

    PutInfoLables();
    UpdateInfoLabels();
    UpdateTrendLabels();
    SetTradeTimeLabel(gs_isTradeTime);
    SetStopTradeLabel(gs_stopTrading);

    return INIT_SUCCEEDED;
}


void OnDeinit(const int reason) {
    DeleteMyObjects();
}

void DeleteMyObjects() {
    ObjectDelete(gs_chartId, LBL_COMMENT);
    ObjectDelete(gs_chartId, LBL_TRADE_ENV);
    ObjectDelete(gs_chartId, LBL_PRICE);
    ObjectDelete(gs_chartId, LBL_TRENDING_TEXT);
    ObjectDelete(gs_chartId, LBL_TREND_LONG);
    ObjectDelete(gs_chartId, LBL_TREND_SHORT);
    ObjectDelete(gs_chartId, LBL_SAR_INDICATOR);
    ObjectDelete(gs_chartId, LBL_SPREAD);
    ObjectDelete(gs_chartId, LBL_SERVER_TIME);
    ObjectDelete(gs_chartId, LBL_LOCAL_TIME);
    ObjectDelete(gs_chartId, LBL_TRADE_TIME);
    ObjectDelete(gs_chartId, LBL_STOP_TRADE);
    ObjectDelete(gs_chartId, LBL_BUY_PARAM);
    ObjectDelete(gs_chartId, LBL_SELL_PARAM);
    ObjectDelete(gs_chartId, LBL_BASIC_PARAM);
    ObjectDelete(gs_chartId, LBL_MAX_LOSS_AMT);
    ObjectDelete(gs_chartId, LBL_CLEANUP_TEXT);
    ObjectDelete(gs_chartId, LBL_POSITION_DAYS);
}

void OnTick() {
    gs_isTradeTime = IsTradeTime(TRADE_DAYS, TRADE_START_HOUR, TRADE_END_HOUR);
    gs_stopTrading = (bool)GlobalVariableGet(GV_STOP_TRADE);

    UpdateInfoLabels();

    //check stop trade flag
    if(gs_stopTrading)  return;

    //Take profit/Stop lose control by amount when
    //1. single chart, no matter in trading time or not
    //2. multi chart and in trading time of this chart
    if((!USE_MULTI_CHARTS) || (USE_MULTI_CHARTS && gs_isTradeTime)) {
        //stop loss control by amount
        if(IsReachStopLossAmount(STOP_LOSS_AMOUNT)) {
            Print("Loss exceed $", STOP_LOSS_AMOUNT, ", closing position...");
            CloseMarketOrders(gs_buyPosition);
            CloseMarketOrders(gs_sellPosition);
            if(STOP_TRADE_AFTER_STOP_LOSS) {
                GlobalVariableSet(GV_STOP_TRADE, 1);   //set stop tradiing GV to true
                gs_stopTrading = true;
                SetStopTradeLabel(gs_stopTrading);
            }
            //refresh current position
            CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
            CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);
            Print("Current position: BUY = ", ArraySize(gs_buyPosition), ", SELL = ", ArraySize(gs_sellPosition));
        }

        //take profit control by amount
        if(IsReachTakeProfitAmount(TAKE_PROFIT_AMOUNT)) {
            Print("Profit exceed $", TAKE_PROFIT_AMOUNT, ", closing position...");
            CloseMarketOrders(gs_buyPosition);
            CloseMarketOrders(gs_sellPosition);
            //refresh current position
            CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
            CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);
            Print("Current position: BUY = ", ArraySize(gs_buyPosition), ", SELL = ", ArraySize(gs_sellPosition));
        }

        if(AccountProfit() < gs_maxLossAmt) {
            gs_maxLossAmt = NormalizeDouble(AccountProfit(), 2);
            WriteData(gs_fileName, gs_maxLossAmtKey, StringFormat("%.2f", MathAbs(gs_maxLossAmt)));
            PrintFormat("Max loss amount reached $%.2f", MathAbs(gs_maxLossAmt));
        }
    }

    if(!HasNewBar())   return;

    //====== New K bar found ===============
    //export orders closed in previous day
    if(EXPORT_TXN_LOG && TimeToString(TimeCurrent(), TIME_DATE) != gs_lastExportDate) {
        ExportTradeHistory(gs_symbol, "", "", MAGIC_NUMBER);
        gs_lastExportDate = TimeToString(TimeCurrent(), TIME_DATE);
    }

    //check current trend
    gs_currentTrend = GetTrendByAlligator(PRICE_CLOSE);
    UpdateTrendLabels();

    //check trading time
    if(!gs_isTradeTime)  return;

    //refresh current position
    CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
    CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);

    //place order if criteria meet
    PlaceOrder(gs_buyPosition, OP_BUY);
    PlaceOrder(gs_sellPosition, OP_SELL);
    Print("Current position: BUY = ", ArraySize(gs_buyPosition), ", SELL = ", ArraySize(gs_sellPosition));
}


//下單邏輯
void PlaceOrder(OrderStruct& orders[], int orderType) {
    int lastOrderIdx = ArraySize(orders) - 1;
    bool isReadyToPlaceOrder = false;
    string orderComment = BuildOrderComment(orderType, lastOrderIdx + 1);
    double orderPrice;
    double orderLots;
    double initLots;
    int maxOrders;
    int expectedTrend;
    int expectedSignal;
    int currentDistance;
    int martinDistance;
    double multiplier;
    string orderTypeString;

    if(orderType == OP_BUY) {
        expectedTrend = TREND_LONG;
        expectedSignal = SIGNAL_BUY;
        orderTypeString = "BUY";
        orderPrice = Ask;
        initLots = gs_buyInitialLots;
        orderLots = initLots;
        maxOrders = gs_buyMartinMaxOrders;
        currentDistance = (lastOrderIdx >= 0)? PriceToInteger(orders[lastOrderIdx].openPrice - orderPrice) : 0;
        martinDistance = gs_buyMartinDistance + gs_buyMartinDistanceIncrement * lastOrderIdx;
        multiplier = gs_buyMartinMultiplier;
    } else {
        expectedTrend = TREND_SHORT;
        expectedSignal = SIGNAL_SELL;
        orderTypeString = "SELL";
        orderPrice = Bid;
        initLots = gs_sellInitialLots;
        orderLots = initLots;
        maxOrders = gs_sellMartinMaxOrders;
        currentDistance = (lastOrderIdx >= 0)? PriceToInteger(orderPrice - orders[lastOrderIdx].openPrice) : 0;
        martinDistance = gs_sellMartinDistance + gs_sellMartinDistanceIncrement * lastOrderIdx;
        multiplier = gs_sellMartinMultiplier;
    }
    PrintFormat("Current %s price = %.5f, distance = %.0f, martin distance = %.0f, martin orders = %.0f", orderTypeString, orderPrice, currentDistance, martinDistance, lastOrderIdx);

    if(lastOrderIdx < 0  && !ENABLE_CLEAN_UP_MODE) {  //初始單
        Print("Placing initial ", orderTypeString, " order.");
        if(USE_TREND_FOR_FIRST_ORDER) {  //趨勢判斷
            if(GetSignalBySAR(0) == expectedSignal) {
                isReadyToPlaceOrder = true;
                Print("Checked SAR signal, ready to ", orderTypeString);
            }
            else {
                isReadyToPlaceOrder = false;
                Print("Checked SAR signal, REJECT to ", orderTypeString);
            }
        } else {
            isReadyToPlaceOrder = true;
            Print("Ignore SAR check, ready to ", orderTypeString);
        }
        orderLots = initLots;

    } else if(lastOrderIdx < maxOrders && currentDistance > martinDistance) {  //馬丁單
        Print("Reached martin criteria, placing ", orderTypeString, " order.");
        if(USE_TREND_FOR_MARTIN_ORDER) {  //趨勢判斷
            if(gs_currentTrend == expectedTrend || gs_currentTrend == TREND_NONE) {
                isReadyToPlaceOrder = true;
                Print("Checked martin trend, ready to ", orderTypeString);
            }
            else {
                isReadyToPlaceOrder = false;
                Print("Checked martin trend, REJECT to ", orderTypeString);
            }
        } else {
            isReadyToPlaceOrder = true;
            Print("Ignore martin trend check, ready to ", orderTypeString);
        }
        orderLots = NormalizeDouble(orders[lastOrderIdx].lots * multiplier, 2);
    }

    if(ENABLE_KD_PROTECTION) {
        double kdValue = GetStochastic(Period(), MODE_MAIN, 1);

        if(orderType == OP_BUY) {
            if(kdValue < 20) {
                isReadyToPlaceOrder = false;
                PrintFormat("KD value = %.4f, reject to %s", kdValue, orderTypeString);
            }

        } else {
            if(kdValue > 80) {
                isReadyToPlaceOrder = false;
                PrintFormat("KD value = %.4f, reject to %s", kdValue, orderTypeString);
            }
        }
    }

    if(isReadyToPlaceOrder) {
        Print("Sending ", orderTypeString, " order...");
        int ticket = SendOrder(gs_symbol, orderType, orderPrice, orderLots, orderComment, MAGIC_NUMBER);

        if(ticket > 0) {
            if(AddTicketToPosition(ticket, orders))
                SetTakeProfit(orders, orderType);
        }
    }
}


//設定獲利點
void SetTakeProfit(OrderStruct& orders[], int orderType) {
    string orderTypeString = (orderType == OP_BUY)? "BUY" : "SELL";
    Print("Setting take profit for ", orderTypeString, " orders...");

    int lastOrderIdx = ArraySize(orders) - 1;
    if(lastOrderIdx < 0) return;

    //calculate average cost
    int i;
    double totalCost = 0;
    double totalLots = 0;
    double avgCost = 0;
    for(i = 0; i <= lastOrderIdx; i++) {
        totalLots += orders[i].lots;
        totalCost += orders[i].lots * orders[i].openPrice;
    }
    avgCost = totalCost / totalLots;
    PrintFormat("Total cost = %.5f, total lots = %.2f, avg. cost = %.5f", totalCost, totalLots, avgCost);

    //取得需使用的獲利點數
    bool useSaperatedTakeProfit;
    int takeProfitPoint;
    double takeProfitPrice;
    if(orderType == OP_BUY) {
        useSaperatedTakeProfit = BUY_USE_SAPERATED_TAKE_PROFIT;
        if(useSaperatedTakeProfit)  takeProfitPoint = BUY_TAKE_PROFIT;
        else takeProfitPoint = (lastOrderIdx == 0)? gs_buyInitialTakeProfit : gs_buyMartinTakeProfit;
    } else {
        useSaperatedTakeProfit = SELL_USE_SAPERATED_TAKE_PROFIT;
        if(useSaperatedTakeProfit)  takeProfitPoint = -SELL_TAKE_PROFIT;
        else takeProfitPoint = (lastOrderIdx == 0)? -gs_sellInitialTakeProfit : -gs_sellMartinTakeProfit;
    }

    //正常單或馬丁單出場, 用平均成本計算獲利價格
    takeProfitPrice = avgCost + takeProfitPoint * Point;
    PrintFormat("Saperated TP = %s, TP point = %d, TP price = %.5f", (string)useSaperatedTakeProfit, MathAbs(takeProfitPoint), takeProfitPrice);

    //modify orders take profit price
    for(i = 0; i <= lastOrderIdx; i++) {
        if(useSaperatedTakeProfit)  //單獨出場, 重新以該單成本計算獲利點
            takeProfitPrice = orders[i].openPrice + takeProfitPoint * Point;

        PrintFormat("Setting ticket %d TP to %.5f", orders[i].ticket, takeProfitPrice);
        ModifyOrder(orders[i].ticket, orders[i].orderType, orders[i].openPrice, orders[i].stopLoss, takeProfitPrice);
    }
}


//交易單註解
string BuildOrderComment(int orderType, int orderSeq) {
    if(orderType == OP_BUY)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_B-" + (string)orderSeq;

    if(orderType == OP_SELL)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_S-" + (string)orderSeq;

    return NULL;
}


//在圖表上安置各項資訊標籤物件
void PutInfoLables() {
    DeleteMyObjects();

    //comment label
    ObjectCreate(gs_chartId, LBL_COMMENT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_YDISTANCE, 24);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(gs_chartId, LBL_COMMENT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_COMMENT, OBJPROP_FONT, "微軟正黑體");
    string custComment = CUSTOM_COMMENT;
    ENUM_ACCOUNT_TRADE_MODE accountType = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
    switch(accountType) {
        case ACCOUNT_TRADE_MODE_DEMO:
            custComment += "模擬倉";
            break;
        case ACCOUNT_TRADE_MODE_REAL:
            custComment += "真倉";
            break;
        default:
            break;
    }
    SetLabelText(gs_chartId, LBL_COMMENT, custComment);

    //交易品種及時區
    ObjectCreate(gs_chartId, LBL_TRADE_ENV, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_YDISTANCE, 45);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_COLOR, clrOrange);
    ObjectSetInteger(gs_chartId, LBL_TRADE_ENV, OBJPROP_FONTSIZE, 18);
    ObjectSetString(gs_chartId, LBL_TRADE_ENV, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_TRADE_ENV, Symbol() + "-" + GetTimeFrameString(Period()));

    //價格
    ObjectCreate(gs_chartId, LBL_PRICE, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_YDISTANCE, 72);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_COLOR, clrDeepSkyBlue);
    ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_FONTSIZE, 24);
    ObjectSetString(gs_chartId, LBL_PRICE, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_PRICE, StringFormat("%.5f", NormalizeDouble((Ask + Bid) / 2, 5)));

    //趨勢標題
    ObjectCreate(gs_chartId, LBL_TRENDING_TEXT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_XDISTANCE, 90);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_COLOR, clrNavajoWhite);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_FONT, "微軟正黑體");
    SetLabelText(gs_chartId, LBL_TRENDING_TEXT, "趨勢：");

    //向上箭頭
    ObjectCreate(gs_chartId, LBL_TREND_LONG, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_XDISTANCE, 78);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_COLOR, clrDeepSkyBlue);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TREND_LONG, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_TREND_LONG, ARROW_UP);

    //向下箭頭
    ObjectCreate(gs_chartId, LBL_TREND_SHORT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_XDISTANCE, 66);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_COLOR, clrDeepPink);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TREND_SHORT, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_TREND_SHORT, ARROW_DOWN);

    //買賣氣指標(SAR)
    ObjectCreate(gs_chartId, LBL_SAR_INDICATOR, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_XDISTANCE, 50);
    ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_FONT, "Verdana");
    int sarInd = GetSignalBySAR(0);
    if(sarInd == SIGNAL_BUY) {
        ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_COLOR, clrDeepSkyBlue);
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, CIRCLE);
    } else if(sarInd == SIGNAL_SELL) {
        ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_COLOR, clrDeepPink);
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, CIRCLE);
    } else {
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, ARROW_NONE);
    }

    //點差
    ObjectCreate(gs_chartId, LBL_SPREAD, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_COLOR, clrNavajoWhite);
    ObjectSetInteger(gs_chartId, LBL_SPREAD, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_SPREAD, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_SPREAD, StringFormat("(%.0f)", MarketInfo(gs_symbol, MODE_SPREAD)));

    //清倉模式
    ObjectCreate(gs_chartId, LBL_CLEANUP_TEXT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_YDISTANCE, 124);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_FONTSIZE, 16);
    ObjectSetString(gs_chartId, LBL_CLEANUP_TEXT, OBJPROP_FONT, "微軟正黑體");
    SetLabelText(gs_chartId, LBL_CLEANUP_TEXT, ENABLE_CLEAN_UP_MODE? "清倉模式開啟" : "");

    //留倉天數
    ObjectCreate(gs_chartId, LBL_POSITION_DAYS, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_YDISTANCE, 50);
    ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_POSITION_DAYS, OBJPROP_FONT, "微軟正黑體");
    double buyDays = (ArraySize(gs_buyPosition) > 0)? TimeCurrent() - gs_buyPosition[0].openTime : 0.0;
    double sellDays = (ArraySize(gs_sellPosition) > 0)? TimeCurrent() - gs_sellPosition[0].openTime : 0.0;
    buyDays =  buyDays / (60 * 60 * 24);
    sellDays = sellDays / (60 * 60 * 24);
    string positionDays = "";
    if(buyDays > 3 || sellDays > 3) {
        ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_COLOR, clrRed);
        positionDays = StringFormat("留倉(天)：BUY  %.0f ; SELL  %.0f", buyDays, sellDays);
    }
    SetLabelText(gs_chartId, LBL_POSITION_DAYS, positionDays);

    //主機時間
    ObjectCreate(gs_chartId, LBL_SERVER_TIME, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_COLOR, clrLimeGreen);
    ObjectSetInteger(gs_chartId, LBL_SERVER_TIME, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, LBL_SERVER_TIME, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_SERVER_TIME, "主機：" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));

    //本機時間
    ObjectCreate(gs_chartId, LBL_LOCAL_TIME, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_YDISTANCE, 15);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_COLOR, clrLimeGreen);
    ObjectSetInteger(gs_chartId, LBL_LOCAL_TIME, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, LBL_LOCAL_TIME, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_LOCAL_TIME, "本地：" + TimeToString(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));

    //基本參數
    ObjectCreate(gs_chartId, LBL_BASIC_PARAM, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_YDISTANCE, 22);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_COLOR, clrDarkOrange);
    ObjectSetInteger(gs_chartId, LBL_BASIC_PARAM, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_BASIC_PARAM, OBJPROP_FONT, "Consolas");
    string basicParam = StringFormat("Param: %d-%d, TP$=%.2f, SL$=%.2f, Profit$=%.2f", TRADE_START_HOUR, TRADE_END_HOUR, TAKE_PROFIT_AMOUNT, STOP_LOSS_AMOUNT, AccountProfit());
    SetLabelText(gs_chartId, LBL_BASIC_PARAM, basicParam);

    //Buy 參數
    ObjectCreate(gs_chartId, LBL_BUY_PARAM, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_YDISTANCE, 42);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_COLOR, clrDarkOrange);
    ObjectSetInteger(gs_chartId, LBL_BUY_PARAM, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_BUY_PARAM, OBJPROP_FONT, "Consolas");
    string buyParam = StringFormat("  BUY: %.2f/%.0f %.3fx/%d+%d/%d/%d", gs_buyInitialLots, gs_buyInitialTakeProfit, gs_buyMartinMultiplier, gs_buyMartinDistance, gs_buyMartinDistanceIncrement, gs_buyMartinTakeProfit, gs_buyMartinMaxOrders);
    SetLabelText(gs_chartId, LBL_BUY_PARAM, buyParam);

    //Sell 參數
    ObjectCreate(gs_chartId, LBL_SELL_PARAM, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_YDISTANCE, 62);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_COLOR, clrDarkOrange);
    ObjectSetInteger(gs_chartId, LBL_SELL_PARAM, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_SELL_PARAM, OBJPROP_FONT, "Consolas");
    string sellParam = StringFormat(" SELL: %.2f/%.0f %.3fx/%d+%d/%d/%d", gs_sellInitialLots, gs_sellInitialTakeProfit, gs_sellMartinMultiplier, gs_sellMartinDistance, gs_sellMartinDistanceIncrement, gs_sellMartinTakeProfit, gs_sellMartinMaxOrders);
    SetLabelText(gs_chartId, LBL_SELL_PARAM, sellParam);

    //最大浮虧金額
    ObjectCreate(gs_chartId, LBL_MAX_LOSS_AMT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_YDISTANCE, 15);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, LBL_MAX_LOSS_AMT, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_MAX_LOSS_AMT, StringFormat("最大浮虧 $%.2f", MathAbs(gs_maxLossAmt)));
}


//設定標籤文字內容
void SetLabelText(long chartId, string labelName, string labelText) {
    ObjectSetString(chartId, labelName, OBJPROP_TEXT, labelText);
}


//更新資訊標籤內容
void UpdateInfoLabels() {
    double medianPrice = NormalizeDouble((Ask + Bid) / 2, 5);
    SetLabelText(gs_chartId, LBL_PRICE, StringFormat("%.5f", medianPrice));
    if(medianPrice > Open[0])
        ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_COLOR, clrDeepSkyBlue);
    else if(medianPrice < Open[0])
        ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_COLOR, clrDeepPink);
    else
        ObjectSetInteger(gs_chartId, LBL_PRICE, OBJPROP_COLOR, clrDarkGray);

    SetLabelText(gs_chartId, LBL_SPREAD, StringFormat("(%.0f)", MarketInfo(gs_symbol, MODE_SPREAD)));

    SetLabelText(gs_chartId, LBL_SERVER_TIME, "主機：" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
    SetLabelText(gs_chartId, LBL_LOCAL_TIME, "本地：" + TimeToString(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));

    string basicParam = StringFormat("Param: %d-%d, TP$=%.2f, SL$=%.2f, Profit$=%.2f", TRADE_START_HOUR, TRADE_END_HOUR, TAKE_PROFIT_AMOUNT, STOP_LOSS_AMOUNT, AccountProfit());
    SetLabelText(gs_chartId, LBL_BASIC_PARAM, basicParam);

    SetLabelText(gs_chartId, LBL_MAX_LOSS_AMT, StringFormat("最大浮虧 $%.2f", MathAbs(gs_maxLossAmt)));

    SetTradeTimeLabel(gs_isTradeTime);
    SetStopTradeLabel(gs_stopTrading);

    double buyDays = (ArraySize(gs_buyPosition) > 0)? TimeCurrent() - gs_buyPosition[0].openTime : 0.0;
    double sellDays = (ArraySize(gs_sellPosition) > 0)? TimeCurrent() - gs_sellPosition[0].openTime : 0.0;
    buyDays =  buyDays / (60 * 60 * 24);
    sellDays = sellDays / (60 * 60 * 24);
    string positionDays = "";
    if(buyDays > 3 || sellDays > 3) {
        ObjectSetInteger(gs_chartId, LBL_POSITION_DAYS, OBJPROP_COLOR, clrRed);
        positionDays = StringFormat("留倉(天)：BUY  %.0f ; SELL  %.0f", buyDays, sellDays);
    }
    SetLabelText(gs_chartId, LBL_POSITION_DAYS, positionDays);
}


//更新趨勢標籤顯示狀態
void UpdateTrendLabels() {
    if(gs_currentTrend == TREND_LONG) {
        SetLabelText(gs_chartId, LBL_TREND_LONG, ARROW_UP);
        SetLabelText(gs_chartId, LBL_TREND_SHORT, ARROW_NONE);
        Print("Current trend is LONG.");

    } else if(gs_currentTrend == TREND_SHORT) {
        SetLabelText(gs_chartId, LBL_TREND_LONG, ARROW_NONE);
        SetLabelText(gs_chartId, LBL_TREND_SHORT, ARROW_DOWN);
        Print("Current trend is SHORT.");

    } else {
        SetLabelText(gs_chartId, LBL_TREND_LONG, ARROW_UP);
        SetLabelText(gs_chartId, LBL_TREND_SHORT, ARROW_DOWN);
        Print("Current trend is unknown.");
    }

    int sarInd = GetSignalBySAR(0);
    if(sarInd == SIGNAL_BUY) {
        ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_COLOR, clrDeepSkyBlue);
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, CIRCLE);
    } else if(sarInd == SIGNAL_SELL) {
        ObjectSetInteger(gs_chartId, LBL_SAR_INDICATOR, OBJPROP_COLOR, clrDeepPink);
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, CIRCLE);
    } else {
        SetLabelText(gs_chartId, LBL_SAR_INDICATOR, ARROW_NONE);
    }
}


//控制顯示超過進場時間訊息
void SetTradeTimeLabel(bool isTradeTime) {
    if(isTradeTime) {
        ObjectDelete(gs_chartId, LBL_TRADE_TIME);

    } else {
        ObjectCreate(gs_chartId, LBL_TRADE_TIME, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_XDISTANCE, 320);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_YDISTANCE, 60);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(gs_chartId, LBL_TRADE_TIME, OBJPROP_FONTSIZE, 24);
        ObjectSetString(gs_chartId, LBL_TRADE_TIME, OBJPROP_FONT, "微軟正黑體");
        SetLabelText(gs_chartId, LBL_TRADE_TIME, TRADE_TIME_MSG);
    }
}


//控制顯示停損暫停交易訊息
void SetStopTradeLabel(bool isStopTrading) {
    if(isStopTrading) {
        ObjectCreate(gs_chartId, LBL_STOP_TRADE, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_XDISTANCE, 90);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_YDISTANCE, 100);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_FONTSIZE, 32);
        ObjectSetString(gs_chartId, LBL_STOP_TRADE, OBJPROP_FONT, "微軟正黑體");
        SetLabelText(gs_chartId, LBL_STOP_TRADE, STOP_TRADE_MSG);

    } else {
        ObjectDelete(gs_chartId, LBL_STOP_TRADE);
    }
}
