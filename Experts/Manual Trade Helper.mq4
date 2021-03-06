#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.05"
#property description "手動操作小幫手"
#property strict
#include <TEA.mqh>

enum enumMagicNumber {
    NONE     = 0,         //不指定
    SingleSD = 88881000,  //牧羊犬
    DoubleSD = 88882000,  //雙頭犬
    BullSD   = 88882000,  //鬥牛犬
    FlashSD  = 88883000,  //閃電犬
//    SuperSD  = 88886000   //超級犬
};

//使用者輸入參數
input string          CUSTOM_COMMENT  = "【手動操作小幫手】";  //畫面註解
input enumMagicNumber MAGIC_NUMBER    = NONE;                  //要模擬的程式
input string          BREAK_LINE_1    = "＝＝＝＝＝";          //＝ [ 預設 BUY 單手數 ] ＝＝＝＝＝＝
input double          BUY1_LOTS       = 0.1;                   //BUY 單手數 1
input double          BUY2_LOTS       = 0.5;                   //BUY 單手數 2
input double          BUY3_LOTS       = 1;                     //BUY 單手數 3
input double          BUY4_LOTS       = 2;                     //BUY 單手數 4
input string          BREAK_LINE_2    = "＝＝＝＝＝";          //＝ [ 預設 SELL 單手數 ] ＝＝＝＝＝＝
input double          SELL1_LOTS      = 0.1;                   //SELL 單手數 1
input double          SELL2_LOTS      = 0.5;                   //SELL 單手數 2
input double          SELL3_LOTS      = 1;                     //SELL 單手數 3
input double          SELL4_LOTS      = 2;                     //SELL 單手數 4
input string          BREAK_LINE_3    = "＝＝＝＝＝";          //＝ [ 獲利點數 ] ＝＝＝＝＝＝
input int             TAKE_PROFIT_GRP = 50;                    //平均獲利點數 (0 表示不設定)
input int             TAKE_PROFIT_IND = 50;                    //分離獲利點數 (0 表示不設定)

//畫面上的物件名稱
const string LBL_COMMENT         = "lblComment";
const string LBL_TRADE_ENV       = "lblTradEvn";
const string LBL_PRICE           = "lblPrice";
const string LBL_SERVER_TIME     = "lblServerTime";
const string LBL_LOCAL_TIME      = "lblLocalTime";
const string LBL_PROFIT          = "lblProfit";
const string BTN_BUY1            = "btnBuy1";
const string BTN_BUY2            = "btnBuy2";
const string BTN_BUY3            = "btnBuy3";
const string BTN_BUY4            = "btnBuy4";
const string BTN_BUY_CLOSE_ALL   = "btnBuyCloseAll";
const string BTN_BUY_SET_TP_GRP  = "btnBuySetTpGrp";
const string BTN_BUY_SET_TP_IND  = "btnBuySetTpInd";
const string BTN_SELL1           = "btnSell1";
const string BTN_SELL2           = "btnSell2";
const string BTN_SELL3           = "btnSell3";
const string BTN_SELL4           = "btnSell4";
const string BTN_SELL_CLOSE_ALL  = "btnSellCloseAll";
const string BTN_SELL_SET_TP_GRP = "btnSellSetTpGrp";
const string BTN_SELL_SET_TP_IND = "btnSellSetTpInd";
const string BTN_CLOSE_ALL       = "btnCloseAll";


//全域變數
static string      gs_symbol      = Symbol();
static long        gs_chartId     = 0;
static int         gs_magicNumber = 0;
static OrderStruct gs_buyOrders[];
static OrderStruct gs_sellOrders[];


int OnInit() {
    Print("Initializing ...");
    
    gs_symbol = Symbol();
    gs_chartId = ChartID();
    gs_magicNumber = (int)MAGIC_NUMBER;
    
    PutInfoLables();
    UpdateInfoLabels();

    return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason) {
    DeleteMyObjects();
}

void DeleteMyObjects() {
    ObjectDelete(gs_chartId, LBL_COMMENT);
    ObjectDelete(gs_chartId, LBL_TRADE_ENV);
    ObjectDelete(gs_chartId, LBL_PRICE);
    ObjectDelete(gs_chartId, LBL_SERVER_TIME);
    ObjectDelete(gs_chartId, LBL_LOCAL_TIME);
    ObjectDelete(gs_chartId, LBL_PROFIT);
    ObjectDelete(gs_chartId, BTN_BUY1);
    ObjectDelete(gs_chartId, BTN_BUY2);
    ObjectDelete(gs_chartId, BTN_BUY3);
    ObjectDelete(gs_chartId, BTN_BUY4);
    ObjectDelete(gs_chartId, BTN_BUY_CLOSE_ALL);
    ObjectDelete(gs_chartId, BTN_BUY_SET_TP_GRP);
    ObjectDelete(gs_chartId, BTN_BUY_SET_TP_IND);
    ObjectDelete(gs_chartId, BTN_SELL1);
    ObjectDelete(gs_chartId, BTN_SELL2);
    ObjectDelete(gs_chartId, BTN_SELL3);
    ObjectDelete(gs_chartId, BTN_SELL4);
    ObjectDelete(gs_chartId, BTN_SELL_CLOSE_ALL);
    ObjectDelete(gs_chartId, BTN_SELL_SET_TP_GRP);
    ObjectDelete(gs_chartId, BTN_SELL_SET_TP_IND);
    ObjectDelete(gs_chartId, BTN_CLOSE_ALL);
}


void OnTick() {
    UpdateInfoLabels();
}


void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

    if(sparam == BTN_BUY1) {
        SendOrder(gs_symbol, OP_BUY, Bid, BUY1_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_BUY2) {
        SendOrder(gs_symbol, OP_BUY, Bid, BUY2_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_BUY3) {
        SendOrder(gs_symbol, OP_BUY, Bid, BUY3_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_BUY4) {
        SendOrder(gs_symbol, OP_BUY, Bid, BUY4_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_BUY_SET_TP_GRP) {
        CollectOrders(gs_symbol, OP_BUY, gs_magicNumber, gs_buyOrders);
        SetTakeProfit(gs_buyOrders, OP_BUY, true);
    }
    if(sparam == BTN_BUY_SET_TP_IND) {
        CollectOrders(gs_symbol, OP_BUY, gs_magicNumber, gs_buyOrders);
        SetTakeProfit(gs_buyOrders, OP_BUY, false);
    }
    if(sparam == BTN_BUY_CLOSE_ALL) {
        CollectOrders(gs_symbol, OP_BUY, gs_magicNumber, gs_buyOrders);
        CloseMarketOrders(gs_buyOrders);
    }

    if(sparam == BTN_SELL1) {
        SendOrder(gs_symbol, OP_SELL, Ask, SELL1_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_SELL2) {
        SendOrder(gs_symbol, OP_SELL, Ask, SELL2_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_SELL3) {
        SendOrder(gs_symbol, OP_SELL, Ask, SELL3_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_SELL4) {
        SendOrder(gs_symbol, OP_SELL, Ask, SELL4_LOTS, "", gs_magicNumber);
    }
    if(sparam == BTN_SELL_SET_TP_GRP) {
        CollectOrders(gs_symbol, OP_SELL, gs_magicNumber, gs_sellOrders);
        SetTakeProfit(gs_sellOrders, OP_SELL, true);
    }
    if(sparam == BTN_SELL_SET_TP_IND) {
        CollectOrders(gs_symbol, OP_SELL, gs_magicNumber, gs_sellOrders);
        SetTakeProfit(gs_sellOrders, OP_SELL, false);
    }
    if(sparam == BTN_SELL_CLOSE_ALL) {
        CollectOrders(gs_symbol, OP_SELL, gs_magicNumber, gs_sellOrders);
        CloseMarketOrders(gs_sellOrders);
    }

    if(sparam == BTN_CLOSE_ALL) {
        CollectOrders(gs_symbol, OP_SELL, gs_magicNumber, gs_sellOrders);
        CloseMarketOrders(gs_sellOrders);
        CollectOrders(gs_symbol, OP_BUY, gs_magicNumber, gs_buyOrders);
        CloseMarketOrders(gs_buyOrders);
    }

    ObjectSetInteger(gs_chartId, sparam, OBJPROP_STATE, false);
}



//設定獲利點
void SetTakeProfit(OrderStruct& orders[], int orderType, bool groupedTp) {
    string orderTypeString = (orderType == OP_BUY)? "BUY" : "SELL";
    Print("Setting take profit for ", orderTypeString, " orders...");
    
    int lastOrderIdx = ArraySize(orders) - 1;
    if(lastOrderIdx < 0) return;

    if(groupedTp) {
        if(TAKE_PROFIT_GRP == 0)  return;
        
        //calculate average cost    
        double totalCost = 0;
        double totalLots = 0;
        double avgCost = 0;
        for(int i = 0; i <= lastOrderIdx; i++) {
            totalLots += orders[i].lots;
            totalCost += orders[i].lots * orders[i].openPrice;
        }
        avgCost = totalCost / totalLots;
        PrintFormat("Total cost = %.5f, total lots = %.2f, avg. cost = %.5f", totalCost, totalLots, avgCost);
        
        //取得需使用的獲利點數
        int takeProfitPoint;
        double takeProfitPrice;
        if(orderType == OP_BUY) {
            takeProfitPoint = TAKE_PROFIT_GRP;
        } else {
            takeProfitPoint = -TAKE_PROFIT_GRP;
        }
        
        //正常單或馬丁單出場, 用平均成本計算獲利價格
        takeProfitPrice = avgCost + takeProfitPoint * Point;
    
        //modify orders take profit price
        for(int i = 0; i <= lastOrderIdx; i++) {
            PrintFormat("Setting ticket %d TP to %.5f", orders[i].ticket, takeProfitPrice);
            ModifyOrder(orders[i].ticket, orders[i].orderType, orders[i].openPrice, orders[i].stopLoss, takeProfitPrice);
        }
    
    } else {  //分離獲利
        if(TAKE_PROFIT_IND == 0)  return;

        //取得需使用的獲利點數
        int takeProfitPoint;
        double takeProfitPrice;
        if(orderType == OP_BUY) {
            takeProfitPoint = TAKE_PROFIT_IND;
        } else {
            takeProfitPoint = -TAKE_PROFIT_IND;
        }

        //modify orders take profit price
        for(int i = 0; i <= lastOrderIdx; i++) {
            takeProfitPrice = orders[i].openPrice + takeProfitPoint * Point;
            PrintFormat("Setting ticket %d TP to %.5f", orders[i].ticket, takeProfitPrice);
            ModifyOrder(orders[i].ticket, orders[i].orderType, orders[i].openPrice, orders[i].stopLoss, takeProfitPrice);
        }
        
    }
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

    //損益
    ObjectCreate(gs_chartId, LBL_PROFIT, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_XDISTANCE, 5);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_YDISTANCE, 22);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDarkOrange);
    ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_FONTSIZE, 12);
    ObjectSetString(gs_chartId, LBL_PROFIT, OBJPROP_FONT, "Verdana");
    double currentProfit = AccountProfit();
    double currentProfitPercent = currentProfit / AccountBalance() * 100;
    string profitString = StringFormat("損益%% = %.2f, 金額$ = %.2f", currentProfitPercent, currentProfit);
    if(currentProfit > 0)
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDeepSkyBlue);
    else if(currentProfit < 0)
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDeepPink);
    else
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDarkGray);
    SetLabelText(gs_chartId, LBL_PROFIT, profitString);

    //Buy 1
    ObjectCreate(gs_chartId, BTN_BUY1, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_YDISTANCE, 320);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY1, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY1, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY1, "BUY " + (string)BUY1_LOTS);

    //Buy 2
    ObjectCreate(gs_chartId, BTN_BUY2, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_YDISTANCE, 280);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY2, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY2, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY2, "BUY " + (string)BUY2_LOTS);

    //Buy 3
    ObjectCreate(gs_chartId, BTN_BUY3, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_YDISTANCE, 240);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY3, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY3, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY3, "BUY " + (string)BUY3_LOTS);

    //Buy 4
    ObjectCreate(gs_chartId, BTN_BUY4, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_YDISTANCE, 200);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY4, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY4, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY4, "BUY " + (string)BUY4_LOTS);

    //Buy set group TP
    ObjectCreate(gs_chartId, BTN_BUY_SET_TP_GRP, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_YDISTANCE, 160);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY_SET_TP_GRP, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY_SET_TP_GRP, "平均獲利");

    //Buy set individual TP
    ObjectCreate(gs_chartId, BTN_BUY_SET_TP_IND, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_YDISTANCE, 120);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY_SET_TP_IND, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY_SET_TP_IND, "分離獲利");

    //Buy close all
    ObjectCreate(gs_chartId, BTN_BUY_CLOSE_ALL, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_YDISTANCE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_BUY_CLOSE_ALL, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_BUY_CLOSE_ALL, "BUY 平倉");

    //Sell 1
    ObjectCreate(gs_chartId, BTN_SELL1, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_YDISTANCE, 320);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL1, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL1, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL1, "SELL " + (string)SELL1_LOTS);

    //Sell 2
    ObjectCreate(gs_chartId, BTN_SELL2, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_YDISTANCE, 280);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL2, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL2, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL2, "SELL " + (string)SELL2_LOTS);

    //Sell 3
    ObjectCreate(gs_chartId, BTN_SELL3, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_YDISTANCE, 240);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL3, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL3, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL3, "SELL " + (string)SELL3_LOTS);

    //Sell 4
    ObjectCreate(gs_chartId, BTN_SELL4, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_YDISTANCE, 200);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL4, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetString(gs_chartId, BTN_SELL4, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL4, "SELL " + (string)SELL4_LOTS);

    //Sell set group TP
    ObjectCreate(gs_chartId, BTN_SELL_SET_TP_GRP, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_YDISTANCE, 160);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL_SET_TP_GRP, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL_SET_TP_GRP, "平均獲利");

    //Sell set individual TP
    ObjectCreate(gs_chartId, BTN_SELL_SET_TP_IND, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_YDISTANCE, 120);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL_SET_TP_IND, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL_SET_TP_IND, "分離獲利");

    //Sell close all
    ObjectCreate(gs_chartId, BTN_SELL_CLOSE_ALL, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_XDISTANCE, 100);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_YDISTANCE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_XSIZE, 80);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_SELL_CLOSE_ALL, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_SELL_CLOSE_ALL, "SELL 平倉");

    //Close all
    ObjectCreate(gs_chartId, BTN_CLOSE_ALL, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_ANCHOR, ANCHOR_RIGHT);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_YDISTANCE, 40);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_XSIZE, 170);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_YSIZE, 30);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_COLOR, clrDarkGreen);
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_BGCOLOR, C'236,233,216');
    ObjectSetInteger(gs_chartId, BTN_CLOSE_ALL, OBJPROP_FONTSIZE, 10);
    ObjectSetString(gs_chartId, BTN_CLOSE_ALL, OBJPROP_FONT, "Verdana");
    SetLabelText(gs_chartId, BTN_CLOSE_ALL, "全部平倉");
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

    SetLabelText(gs_chartId, LBL_SERVER_TIME, "主機：" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
    SetLabelText(gs_chartId, LBL_LOCAL_TIME, "本地：" + TimeToString(TimeLocal(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));

    double currentProfit = AccountProfit();
    double currentProfitPercent = currentProfit / AccountBalance() * 100;
    string profitString = StringFormat("損益%% = %.2f, 金額$ = %.2f", currentProfitPercent, currentProfit);
    if(currentProfit > 0)
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDeepSkyBlue);
    else if(currentProfit < 0)
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDeepPink);
    else
        ObjectSetInteger(gs_chartId, LBL_PROFIT, OBJPROP_COLOR, clrDarkGray);
    SetLabelText(gs_chartId, LBL_PROFIT, profitString);
}