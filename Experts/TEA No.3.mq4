#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.66"
#property description "提姆茶３號"
#property description "撒豆子佈局策略, 在預想的震幅區間中"
#property description "每隔固定點距, 手數依等比或等差加減碼, 預掛 stop 單等待成交"
#property description "在指定撒豆時間結束後, 自動轉換為馬丁救援模式, 處理帳上未結的豆子單"
#include <TEA.mqh>

enum enumPutType {
    Arithmetic = 1,   //等差
    Geometric  = 2    //等比
};


//使用者輸入參數
input string      CUSTOM_COMMENT             = "【提姆茶３號】";    //畫面註解
input string      BREAK_LINE_1               = "＝＝＝＝＝";        //＝ [ 進場控制 ] ＝＝＝＝＝＝
input string      START_TIME                 = "";                  //開始時間 (HH:MM)
input string      END_TIME                   = "";                  //結束時間 (HH:MM)
input bool        CONTINUE_PUT_BEAN          = true;                //無 STOP 單時再重新佈局
input bool        AUTO_CANCEL_BEAN           = false;               //依照與市價的差距取消未成交的 STOP 單
input int         RESET_RANGE                = 320;                 //觸發自動取消 STOP 單的點距
input string      BREAK_LINE_2               = "＝＝＝＝＝";        //＝ [風險管理] ＝＝＝＝＝＝
input bool        CLOSE_ALL_ORDERS_LEFT      = false;               //撒豆結束後全部平倉
input bool        STOP_TRADE_AFTER_STOP_LOSS = true;                //停損後暫停下單
input double      STOP_LOSS_AMOUNT           = 0;                   //停損金額 (0: 關閉)
input string      BREAK_LINE_3               = "＝＝＝＝＝";        //＝ [ BUY 佈局模式 ] ＝＝＝＝＝＝
input bool        BUY_PUT_BEANS              = true;                //佈局 BUY 單
input enumPutType BUY_PUT_TYPE               = Geometric;           //BUY 加減碼模式
input double      BUY_THROTTLE               = 0.5;                 //BUY 加減碼差距/比例
input int         BUY_BREAK_POINT            = 750;                 //BUY 加減碼起始點距 (0: 立刻減碼)
input int         BUY_MAX_BEANS              = 10;                  //BUY 佈局張數
input double      BUY_INITIAL_LOTS           = 1;                   //BUY 起始手數
input double      BUY_MINIMUM_LOTS           = 0.01;                //BUY 最小手數
input int         BUY_1ST_DISTANCE           = 100;                 //BUY 首張單距市價點距
input int         BUY_DISTANCE               = 125;                 //BUY 佈局間隔點距
input int         BUY_TAKE_PROFIT            = 100;                 //BUY 停利點 (0: 不設停利)
input int         BUY_STOP_LOSS              = 50;                  //BUY 停損點 (0: 不設停損)
input string      BREAK_LINE_4               = "＝＝＝＝＝";        //＝ [ SELL 佈局模式 ] ＝＝＝＝＝＝
input bool        REPLICATE_BUY_PARAM        = true;                //與 BUY 佈局模式相同
input bool        SELL_PUT_BEANS             = true;                //佈局 SELL 單
input enumPutType SELL_PUT_TYPE              = Geometric;           //SELL 加減碼模式
input double      SELL_THROTTLE              = 0.5;                 //SELL 加減碼差距/比例
input int         SELL_BREAK_POINT           = 750;                 //SELL 加減碼起始點距 (0: 立刻減碼)
input int         SELL_MAX_BEANS             = 10;                  //SELL 佈局張數
input double      SELL_INITIAL_LOTS          = 1;                   //SELL 起始手數
input double      SELL_MINIMUM_LOTS          = 0.01;                //SELL 最小手數
input int         SELL_1ST_DISTANCE          = 100;                 //SELL 首張單距市價點距
input int         SELL_DISTANCE              = 125;                 //SELL 佈局間隔點距
input int         SELL_TAKE_PROFIT           = 100;                 //SELL 停利點 (0: 不設停利)
input int         SELL_STOP_LOSS             = 50;                  //SELL 停損點 (0: 不設停損)
input string      BREAK_LINE_5               = "＝＝＝＝＝";        //＝ [ 馬丁救援模式 ] ＝＝＝＝＝＝
input bool        MARTIN_RESCUE              = false;               //撒豆結束後啟動馬丁救援
input bool        USE_TREND_FOR_MARTIN_ORDER = true;                //馬丁單趨勢判斷
input double      MARTIN_MULTIPLIER          = 3;                   //馬丁比例
input int         MARTIN_DISTANCE            = 200;                 //馬丁點距
input int         MARTIN_DISTANCE_INCREMENT  = 100;                 //馬丁點距增減數
input int         MARTIN_MAX_ORDERS          = 3;                   //馬丁最大張數
input int         MARTIN_TAKE_PROFIT         = 50;                  //馬丁獲利點數


//EA 相關
const int    MAGIC_NUMBER         = 930214;
const string ORDER_COMMENT_PREFIX = "TEA3_";    //交易單說明前置字串


//資訊顯示用的 Label 物件名稱
const string LBL_COMMENT           = "lblComment";
const string LBL_TRADE_ENV         = "lblTradEvn";
const string LBL_PRICE             = "lblPrice";
const string LBL_TRENDING_TEXT     = "lblTrendingText";
const string LBL_TREND_LONG        = "lblTrendingBuy";
const string LBL_TREND_SHORT       = "lblTrendingSell";
const string LBL_SPREAD            = "lblSpread";
const string LBL_SERVER_TIME       = "lblServerTime";
const string LBL_LOCAL_TIME        = "lblLocalTime";
const string LBL_TRADE_TIME        = "lblTradeTime";
const string LBL_STOP_TRADE        = "lblStopTrade";
const string LBL_RUN_MODE          = "lblRunMode";
const string LBL_MAX_LOSS_AMT      = "lblMaxLossAmt";
const string TRADE_TIME_MSG        = "已超出撒豆時間！";
const string STOP_TRADE_MSG        = "已達停損標準，茶棧暫停營業！";
const string ARROW_UP              = "↑";
const string ARROW_DOWN            = "↓";
const string ARROW_NONE            = "　";
const string BTN_CANCEL_BUY_BEANS  = "btnCancelBuyBeans";
const string BTN_CANCEL_SELL_BEANS = "btnCancelSellBeans";


//全域變數
static bool        gs_isTradeTime    = false;
static bool        gs_stopTrading    = false;
static string      gs_symbol         = Symbol();
static long        gs_chartId        = 0;
static int         gs_BuyBeanRounds  = 0;
static int         gs_SellBeanRounds = 0;
static bool        gs_isPuttingBeans = false;
static int         gs_currentTrend   = TREND_NONE;
static bool        gs_rescueModeOn   = false;
static string      gs_fileName       = "TEA3_" + (string)AccountNumber() + ".txt";
static double      gs_maxLossAmt     = 0;
static string      gs_maxLossAmtKey  = "MaxLossAmount";
static OrderStruct gs_buyBeans[];
static OrderStruct gs_sellBeans[];
static OrderStruct gs_buyPosition[];
static OrderStruct gs_sellPosition[];

static enumPutType gs_buyPutType;
static double      gs_buyThrottle;
static int         gs_buyBreakPoint;
static int         gs_buyMaxBeans;
static double      gs_buyInitialLots;
static double      gs_buyMinimumLots;
static int         gs_buy1stDistance;
static int         gs_buyDistance;
static int         gs_buyTakeProfit;
static int         gs_buyStopLoss;
static enumPutType gs_sellPutType;
static double      gs_sellThrottle;
static int         gs_sellBreakPoint;
static int         gs_sellMaxBeans;
static double      gs_sellInitialLots;
static double      gs_sellMinimumLots;
static int         gs_sell1stDistance;
static int         gs_sellDistance;
static int         gs_sellTakeProfit;
static int         gs_sellStopLoss;


int OnInit() {
    Print("Initializing ...");

    gs_symbol = Symbol();
    gs_chartId = ChartID();
    gs_BuyBeanRounds = 0;
    gs_SellBeanRounds = 0;
    gs_currentTrend = GetTrendByAlligator(PRICE_MEDIAN);
    gs_isTradeTime = IsTradeTime(START_TIME, END_TIME);
    gs_rescueModeOn = (!gs_isTradeTime && MARTIN_RESCUE)? true : false;

    gs_buyPutType     = BUY_PUT_TYPE;
    gs_buyThrottle    = BUY_THROTTLE;
    gs_buyBreakPoint  = BUY_BREAK_POINT;
    gs_buyMaxBeans    = BUY_MAX_BEANS;
    gs_buyInitialLots = BUY_INITIAL_LOTS;
    gs_buyMinimumLots = BUY_MINIMUM_LOTS;
    gs_buy1stDistance = BUY_1ST_DISTANCE;
    gs_buyDistance    = BUY_DISTANCE;
    gs_buyTakeProfit  = BUY_TAKE_PROFIT;
    gs_buyStopLoss    = BUY_STOP_LOSS;

    gs_sellPutType     = REPLICATE_BUY_PARAM? BUY_PUT_TYPE     : SELL_PUT_TYPE;
    gs_sellThrottle    = REPLICATE_BUY_PARAM? BUY_THROTTLE     : SELL_THROTTLE;
    gs_sellBreakPoint  = REPLICATE_BUY_PARAM? BUY_BREAK_POINT  : SELL_BREAK_POINT;
    gs_sellMaxBeans    = REPLICATE_BUY_PARAM? BUY_MAX_BEANS    : SELL_MAX_BEANS;
    gs_sellInitialLots = REPLICATE_BUY_PARAM? BUY_INITIAL_LOTS : SELL_INITIAL_LOTS;
    gs_sellMinimumLots = REPLICATE_BUY_PARAM? BUY_MINIMUM_LOTS : SELL_MINIMUM_LOTS;
    gs_sell1stDistance = REPLICATE_BUY_PARAM? BUY_1ST_DISTANCE : SELL_1ST_DISTANCE;
    gs_sellDistance    = REPLICATE_BUY_PARAM? BUY_DISTANCE     : SELL_DISTANCE;
    gs_sellTakeProfit  = REPLICATE_BUY_PARAM? BUY_TAKE_PROFIT  : SELL_TAKE_PROFIT;
    gs_sellStopLoss    = REPLICATE_BUY_PARAM? BUY_STOP_LOSS    : SELL_STOP_LOSS;

    string tmp = ReadData(gs_fileName, gs_maxLossAmtKey);
    if(tmp != "")  gs_maxLossAmt = (double)tmp * -1;

    //refresh current beans
    CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, gs_buyBeans);
    CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, gs_sellBeans);

    //refresh open orders
    CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
    CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);

    PutInfoLables();
    UpdateInfoLabels();
    UpdateTrendLabels();
    SetTradeTimeLabel(gs_isTradeTime);

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
    ObjectDelete(gs_chartId, LBL_SPREAD);
    ObjectDelete(gs_chartId, LBL_SERVER_TIME);
    ObjectDelete(gs_chartId, LBL_LOCAL_TIME);
    ObjectDelete(gs_chartId, LBL_TRADE_TIME);
    ObjectDelete(gs_chartId, LBL_STOP_TRADE);
    ObjectDelete(gs_chartId, LBL_RUN_MODE);
    ObjectDelete(gs_chartId, LBL_MAX_LOSS_AMT);
    ObjectDelete(gs_chartId, BTN_CANCEL_BUY_BEANS);
    ObjectDelete(gs_chartId, BTN_CANCEL_SELL_BEANS);
}

void OnTick() {
    UpdateInfoLabels();

    //stop loss control by amount
    if(IsReachStopLossAmount(STOP_LOSS_AMOUNT)) {
        Print("Loss exceed $", STOP_LOSS_AMOUNT, ", closing position...");

        CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
        CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);
        CloseMarketOrders(gs_buyPosition);
        CloseMarketOrders(gs_sellPosition);

        CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, gs_buyBeans);
        CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, gs_sellBeans);
        DeletePendingOrders(gs_buyBeans);
        DeletePendingOrders(gs_sellBeans);

        if(STOP_TRADE_AFTER_STOP_LOSS) {
            gs_stopTrading = true;
            SetStopTradeLabel(gs_stopTrading);
        }
    }

    if(AccountProfit() < gs_maxLossAmt) {
        gs_maxLossAmt = NormalizeDouble(AccountProfit(), 2);
        WriteData(gs_fileName, gs_maxLossAmtKey, StringFormat("%.2f", MathAbs(gs_maxLossAmt)));
        PrintFormat("Max loss amount reached $%.2f", MathAbs(gs_maxLossAmt));
    }

    if(!HasNewBar())  return;

    //check current trend
    gs_currentTrend = GetTrendByAlligator(PRICE_MEDIAN);
    UpdateTrendLabels();

    gs_isTradeTime = IsTradeTime(START_TIME, END_TIME);
    SetTradeTimeLabel(gs_isTradeTime);

    gs_rescueModeOn = (!gs_isTradeTime && MARTIN_RESCUE)? true : false;
    UpdateInfoLabels();

    if(gs_stopTrading)  return;

    if(gs_isTradeTime) {
        RunBeansMode();

    } else if(gs_rescueModeOn) {
        Print("Not in trading time, rescue mode is ON.");
        RunRescueMode();

    } else {
        Print("Not in trading time and rescue mode is OFF.");

        CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, gs_buyBeans);
        CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, gs_sellBeans);
        DeletePendingOrders(gs_buyBeans);
        DeletePendingOrders(gs_sellBeans);

        //close all orders left
        if(CLOSE_ALL_ORDERS_LEFT) {
            Print("Put bean times up, closing left orders...");
            CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
            CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);
            CloseMarketOrders(gs_buyPosition);
            CloseMarketOrders(gs_sellPosition);
        }
    }
}


void RunBeansMode() {
    if(AUTO_CANCEL_BEAN) {
        Print("Checking if need to cancel beans.");
        ResetBeans(OP_BUYSTOP);
        ResetBeans(OP_SELLSTOP);
    }

    CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, gs_buyBeans);
    CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, gs_sellBeans);

    gs_isPuttingBeans = true;
    if(BUY_PUT_BEANS) {
        PutBeans(gs_buyBeans, OP_BUYSTOP);
    }
    if(SELL_PUT_BEANS) {
        PutBeans(gs_sellBeans, OP_SELLSTOP);
    }
    gs_isPuttingBeans = false;

    Print("Current beans: BUYSTOP = ", ArraySize(gs_buyBeans), ", SELLSTOP = ", ArraySize(gs_sellBeans));
}


void RunRescueMode() {
    int tickets[];

    Print("Entering rescue mode, canceling beans left");
    CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, tickets);
    DeletePendingOrders(tickets);
    CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, tickets);
    DeletePendingOrders(tickets);

    //refresh current position
    CollectOrders(gs_symbol, OP_BUY, MAGIC_NUMBER, gs_buyPosition);
    CollectOrders(gs_symbol, OP_SELL, MAGIC_NUMBER, gs_sellPosition);

    //set take profit
    SetTakeProfit(gs_buyPosition, OP_BUY);
    SetTakeProfit(gs_sellPosition, OP_SELL);

    //place order if there are open orders
    if(ArraySize(gs_buyPosition) > 0) {
        Print("Rescuing BUY orders...");
        PlaceOrder(gs_buyPosition, OP_BUY);
    }
    if(ArraySize(gs_sellPosition) > 0) {
        Print("Rescuing SELL orders...");
        PlaceOrder(gs_sellPosition, OP_SELL);
    }
    Print("Current position: BUY = ", ArraySize(gs_buyPosition), ", SELL = ", ArraySize(gs_sellPosition));
}


void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(gs_isPuttingBeans) {
        Print("Putting beans is in progress, could not delete.");
        return;
    }

    int tickets[];

    if(sparam == BTN_CANCEL_BUY_BEANS) {
        CollectOrders(gs_symbol, OP_BUYSTOP, MAGIC_NUMBER, tickets);
        DeletePendingOrders(tickets);
    }

    if(sparam == BTN_CANCEL_SELL_BEANS) {
        CollectOrders(gs_symbol, OP_SELLSTOP, MAGIC_NUMBER, tickets);
        DeletePendingOrders(tickets);
    }

    ObjectSetInteger(gs_chartId, sparam, OBJPROP_STATE, false);
}


//佈局 stop 單
void PutBeans(OrderStruct& orders[], int orderType) {
    enumPutType putType;
    double      tpPoint;
    double      slPoint;
    double      initDistance;
    double      distance;
    double      orderPrice;
    double      orderLots;
    double      minLots;
    int         maxBeans;
    double      tpPrice;
    double      slPrice;
    double      beanThrottle;
    string      comment;
    int         ticket;
    string      orderTypeString;
    int         putBeanRounds;
    int         breakPoint;

    if(orderType == OP_BUYSTOP) {
        orderTypeString = "BUY";
        putType = gs_buyPutType;
        tpPoint = IntegerToPrice(gs_buyTakeProfit);
        slPoint = IntegerToPrice(gs_buyStopLoss);
        initDistance = IntegerToPrice(gs_buy1stDistance);
        distance = IntegerToPrice(gs_buyDistance);
        orderPrice = Ask;
        orderLots = gs_buyInitialLots;
        maxBeans = gs_buyMaxBeans;
        beanThrottle = gs_buyThrottle;
        minLots = gs_buyMinimumLots;
        putBeanRounds = gs_BuyBeanRounds;
        breakPoint = gs_buyBreakPoint;

    } else {
        orderTypeString = "SELL";
        putType = gs_sellPutType;
        tpPoint = IntegerToPrice(-gs_sellTakeProfit);
        slPoint = IntegerToPrice(-gs_sellStopLoss);
        initDistance = IntegerToPrice(-gs_sell1stDistance);
        distance = IntegerToPrice(-gs_sellDistance);
        orderPrice = Bid;
        orderLots = gs_sellInitialLots;
        maxBeans = gs_sellMaxBeans;
        beanThrottle = gs_sellThrottle;
        minLots = gs_sellMinimumLots;
        putBeanRounds = gs_SellBeanRounds;
        breakPoint = gs_sellBreakPoint;
    }

    if(ArraySize(orders) == 0) {
        if(putBeanRounds == 0) {
            Print("Ready to put round ", putBeanRounds + 1, " ", orderTypeString, " beans.");
        } else if(putBeanRounds > 0 && CONTINUE_PUT_BEAN) {
            Print("Ready to put round ", putBeanRounds + 1, " ", orderTypeString, " beans.");
        } else {
            Print("Not allowed to put 2nd round beans.");
            return;
        }

    } else {
        Print("Found ", orderTypeString, " beans available, stop putting new beans.");
        return;
    }

    double totalLots = 0;
    double firstPrice = 0;
    double lastPrice = 0;

    for(int i = 1; i <= maxBeans; i++) {
        orderPrice += (i == 1)? initDistance : distance;

        if(i > 1 && PriceToInteger(MathAbs(distance)) * i >= breakPoint) {
            if(putType == Arithmetic) {
                orderLots += beanThrottle;
            }
            else {
                orderLots *= beanThrottle;
            }

            if(orderLots < minLots) {
                Print("Order lots is less than minimum lots, stop putting beans.");
                break;
            }
        }

        orderLots = NormalizeDouble(orderLots, 2);
        tpPrice = NormalizeDouble((tpPoint == 0)? 0 : orderPrice + tpPoint, 5);
        slPrice = NormalizeDouble((slPoint == 0)? 0 : orderPrice - slPoint, 5);
        comment = BuildOrderComment(orderType, StringFormat("%d.%d", putBeanRounds + 1, i));

        PrintFormat("Sending %s bean: Price = %.5f, Lots = %.2f, TP = %.5f, SL = %.5f", orderTypeString, orderPrice, orderLots, tpPrice, slPrice);
        ticket = SendOrder(gs_symbol, orderType, orderPrice, orderLots, comment, MAGIC_NUMBER, tpPrice, slPrice);

        if(ticket > 0) {
            AddTicketToPosition(ticket, orders);
            totalLots += orderLots;
            if(i == 1)  {
                firstPrice = orderPrice;
                lastPrice = orderPrice;
            }
            else {
                lastPrice = orderPrice;
            }
        }
    }
    PrintFormat("Total %s lots=%.2f, distance=%.0f", orderTypeString, totalLots, PriceToInteger(MathAbs(lastPrice - firstPrice)));

    if(orderType == OP_BUYSTOP)
        gs_BuyBeanRounds += 1;
    else
        gs_SellBeanRounds += 1;
}


//依最近的 stop 單離市價距離決定是否取消 stop 單
void ResetBeans(int orderType) {
    int currentRange = 0;
    double currentPrice = 0;
    string orderTypeString = "";
    OrderStruct beans[];

    CollectOrders(gs_symbol, orderType, MAGIC_NUMBER, beans);
    if(ArraySize(beans) == 0)  return;

    if(orderType == OP_BUYSTOP) {
        orderTypeString = "BUY STOP";
        currentPrice = Ask;
        currentRange = PriceToInteger(beans[0].openPrice - currentPrice);
    } else {
        orderTypeString = "SELL STOP";
        currentPrice = Bid;
        currentRange = PriceToInteger(currentPrice - beans[0].openPrice);
    }

    PrintFormat("%s ticket %d open price: %.5f, current price: %.5f, diff: %d", orderTypeString, beans[0].ticket, beans[0].openPrice, currentPrice, currentRange);
    if(currentRange > RESET_RANGE) {
        Print("Cancel ", orderTypeString, " beans.");
        DeletePendingOrders(beans);
    }
}


//馬丁救援下單邏輯
void PlaceOrder(OrderStruct& orders[], int orderType) {
    int lastOrderIdx = ArraySize(orders) - 1;
    bool isReadyToPlaceOrder = false;
    string orderComment = BuildOrderComment(orderType, (string)(lastOrderIdx + 1));
    double orderPrice;
    double orderLots = NormalizeDouble(orders[lastOrderIdx].lots * MARTIN_MULTIPLIER, 2);
    int maxOrders = MARTIN_MAX_ORDERS;
    int expectedTrend;
    int currentDistance;
    int martinDistance = MARTIN_DISTANCE + MARTIN_DISTANCE_INCREMENT * lastOrderIdx;
    string orderTypeString;

    if(orderType == OP_BUY) {
        expectedTrend = TREND_LONG;
        orderTypeString = "BUY";
        orderPrice = Ask;
        currentDistance = (lastOrderIdx >= 0)? PriceToInteger(orders[lastOrderIdx].openPrice - orderPrice) : 0;
    } else {
        expectedTrend = TREND_SHORT;
        orderTypeString = "SELL";
        orderPrice = Bid;
        currentDistance = (lastOrderIdx >= 0)? PriceToInteger(orderPrice - orders[lastOrderIdx].openPrice) : 0;
    }
    PrintFormat("Current %s price = %.5f, distance = %.0f, martin distance = %.0f, martin orders = %.0f", orderTypeString, orderPrice, currentDistance, martinDistance, lastOrderIdx);

    if(lastOrderIdx < maxOrders && currentDistance > martinDistance) {  //馬丁單
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
    int takeProfitPoint;
    double takeProfitPrice;
    if(orderType == OP_BUY) {
        takeProfitPoint = MARTIN_TAKE_PROFIT;
    } else {
        takeProfitPoint = -MARTIN_TAKE_PROFIT;
    }

    //正常單或馬丁單出場, 用平均成本計算獲利價格
    takeProfitPrice = avgCost + takeProfitPoint * Point;

    //modify orders take profit price
    for(i = 0; i <= lastOrderIdx; i++) {
        PrintFormat("Setting ticket %d TP to %.5f", orders[i].ticket, takeProfitPrice);
        ModifyOrder(orders[i].ticket, orders[i].orderType, orders[i].openPrice, orders[i].stopLoss, takeProfitPrice);
    }
}


//交易單註解
string BuildOrderComment(int orderType, string orderSeq) {
    if(orderType == OP_BUYSTOP)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_BS-" + orderSeq;

    if(orderType == OP_SELLSTOP)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_SS-" + orderSeq;

    if(orderType == OP_BUY)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_B-" + orderSeq;

    if(orderType == OP_SELL)
        return ORDER_COMMENT_PREFIX + gs_symbol + "_S-" + orderSeq;

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
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_XDISTANCE, 82);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_COLOR, clrNavajoWhite);
    ObjectSetInteger(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TRENDING_TEXT, OBJPROP_FONT, "微軟正黑體");
    SetLabelText(gs_chartId, LBL_TRENDING_TEXT, "趨勢：");

    //向上箭頭
    ObjectCreate(gs_chartId, LBL_TREND_LONG, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_XDISTANCE, 70);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_COLOR, clrDeepSkyBlue);
    ObjectSetInteger(gs_chartId, LBL_TREND_LONG, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TREND_LONG, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_TREND_LONG, ARROW_UP);

    //向下箭頭
    ObjectCreate(gs_chartId, LBL_TREND_SHORT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_XDISTANCE, 58);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_YDISTANCE, 98);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_COLOR, clrDeepPink);
    ObjectSetInteger(gs_chartId, LBL_TREND_SHORT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_TREND_SHORT, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, LBL_TREND_SHORT, ARROW_DOWN);

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

    //執行模式
    ObjectCreate(gs_chartId, LBL_RUN_MODE, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_COLOR, clrDarkOrange);
    ObjectSetInteger(gs_chartId, LBL_RUN_MODE, OBJPROP_FONTSIZE, 18);
    ObjectSetString(gs_chartId, LBL_RUN_MODE, OBJPROP_FONT, "微軟正黑體");
    string runMode = StringFormat("執行模式: %s", (gs_rescueModeOn)? "救援模式" : "撒豆模式");
    SetLabelText(gs_chartId, LBL_RUN_MODE, runMode);

    //delete buy beans button
    ObjectCreate(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_YDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_XSIZE, 130);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_CANCEL_BUY_BEANS, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_CANCEL_BUY_BEANS, "Delete BUY Beans");

    //delete sell beans button
    ObjectCreate(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_YDISTANCE, 65);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_XSIZE, 130);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_CANCEL_SELL_BEANS, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_CANCEL_SELL_BEANS, "Delete SELL Beans");

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

    string runMode = StringFormat("執行模式: %s", (gs_rescueModeOn)? "救援模式" : "撒豆模式");
    SetLabelText(gs_chartId, LBL_RUN_MODE, runMode);

    SetLabelText(gs_chartId, LBL_MAX_LOSS_AMT, StringFormat("最大浮虧 $%.2f", MathAbs(gs_maxLossAmt)));
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
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_YDISTANCE, 120);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(gs_chartId, LBL_STOP_TRADE, OBJPROP_FONTSIZE, 32);
        ObjectSetString(gs_chartId, LBL_STOP_TRADE, OBJPROP_FONT, "微軟正黑體");
        SetLabelText(gs_chartId, LBL_STOP_TRADE, STOP_TRADE_MSG);

    } else {
        ObjectDelete(gs_chartId, LBL_STOP_TRADE);
    }
}
