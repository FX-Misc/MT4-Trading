#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.10"
#property description "撒豆子佈局策略, 在預想的震幅區間中"
#property description "每隔固定點距, 手數依等比或等差減碼, 預掛 stop 單等待成交"
#property strict
#property script_show_inputs

#import "TimUtil.ex4" 
string CompileErrorMessage(int errorCode);
bool HasNewBar();
void CloseOrders(int& orders[]);
bool CollectOrderTickets(string symbol, int orderType, int& tickets[], int magicNumber = 930214);
#import

input string BREAK_LINE_0      = "====="; //== 【佈局模式】 =====
input bool   PUT_BUY_BEANS     = false;   //是否佈局 Buy 單
input bool   PUT_SELL_BEANS    = false;   //是否佈局 Sell 單
input int    PUT_TYPE          = 2;       //佈局模式 (1:等差 2:等比)
input double BEAN_INCREMENT    = 0.2;     //佈局手數減碼差距 (佈局模式為【等差】時使用)
input double BEAN_MULTIPLIER   = 2;       //佈局手數減碼倍率 (佈局模式為【等比】時使用)

input string BREAK_LINE_1      = "====="; //== 【交易參數】 =====
input int    MAX_BEANS         = 10;      //佈局張數
input double INITIAL_LOTS      = 1.28;    //起始手數
input double MINIMUM_LOTS      = 0.01;    //最小手數
input double BEAN_1ST_DISTANCE = 50;      //首張單距市價點距
input int    BEAN_DISTANCE     = 100;     //佈局間隔點距
input int    TAKE_PROFIT       = 100;     //停利點 (0: 不設停利)
input int    STOP_LOSS         = 0;       //停損點 (0: 不設停損)

const int MAGIC_NUMBER        = 930214;
const int PUT_TYPE_ARITHMETIC = 1;
const int PUT_TYPE_GEOMETRIC  = 2;


void OnStart() {
    double tpPoint = TAKE_PROFIT * Point;
    double slPoint = STOP_LOSS * Point;
    double init_distance = BEAN_1ST_DISTANCE * Point;
    double distance = BEAN_DISTANCE * Point;
    double orderPrice;
    double orderLots;
    double tpPrice;
    double slPrice;
    string comment;
    int    ticket;
    
    if(PUT_BUY_BEANS) {
        double totalBuyLots = 0;
        double firstBuyPrice = 0;
        double lastBuyPrice = 0;

        orderPrice = Ask;
        orderLots = INITIAL_LOTS;
        ticket = 0;
        
        for(int i = 1; i <= MAX_BEANS; i++) {
            orderPrice += (i == 1)? init_distance : distance;
            if(PUT_TYPE == PUT_TYPE_ARITHMETIC) {
                orderLots -= (i == 1)? 0 : BEAN_INCREMENT;
            }    
            else {
                orderLots /= (i == 1)? 1 : BEAN_MULTIPLIER;
            }
            if(orderLots < MINIMUM_LOTS) {
                //Print("Order lots reached minimum lots.");
                break;
            }

            orderLots = NormalizeDouble(orderLots, 2);
            tpPrice = (tpPoint == 0)? 0 : orderPrice + tpPoint;
            slPrice = (slPoint == 0)? 0 : orderPrice - slPoint;
            comment = "Bean_B-" + (string)i;
            
            PrintFormat("Putting BUY bean %d.  Price=%.5f, Lots=%.2f, TP=%.5f, SL=%.5f", i, orderPrice, orderLots, tpPrice, slPrice);
            ticket = OrderSend(Symbol(), OP_BUYSTOP, orderLots, orderPrice, 0, slPrice, tpPrice, comment, MAGIC_NUMBER, 0, clrBlue);
            if(ticket > 0) {
                totalBuyLots += orderLots;
                if(i == 1)
                    firstBuyPrice = orderPrice / Point;
                else
                    lastBuyPrice = orderPrice / Point;
            }
            else {
                Alert("佈局 Buy 單豆子發生錯誤: " + CompileErrorMessage(GetLastError()));
            }
        }
        PrintFormat("Total BUY lots=%.2f, distance=%.0f", totalBuyLots, lastBuyPrice - firstBuyPrice);
    }


    if(PUT_SELL_BEANS) {
        double totalSellLots = 0;
        double firstSellPrice = 0;
        double lastSellPrice = 0;

        orderPrice = Bid;
        orderLots = INITIAL_LOTS;
        ticket = 0;
        
        for(int i = 1; i <= MAX_BEANS; i++) {
            orderPrice -= (i == 1)? init_distance : distance;
            if(PUT_TYPE == PUT_TYPE_ARITHMETIC) {
                orderLots -= (i == 1)? 0 : BEAN_INCREMENT;
            }
            else {
                orderLots /= (i == 1)? 1 : BEAN_MULTIPLIER;
            }
            if(orderLots < MINIMUM_LOTS) {
                break;
            }
            orderLots = NormalizeDouble(orderLots, 2);
            tpPrice = (tpPoint == 0)? 0 : orderPrice - tpPoint;
            slPrice = (slPoint == 0)? 0 : orderPrice + slPoint;
            comment = "Bean_S-" + (string)i;

            PrintFormat("Putting SELL bean %d.  Price=%.5f, Lots=%.2f, TP=%.5f, SL=%.5f", i, orderPrice, orderLots, tpPrice, slPrice);
            ticket = OrderSend(Symbol(), OP_SELLSTOP, orderLots, orderPrice, 0, slPrice, tpPrice, comment, MAGIC_NUMBER, 0, clrRed);
            if(ticket > 0) {
                totalSellLots += orderLots;
                if(i == 1)
                    firstSellPrice = orderPrice / Point;
                else
                    lastSellPrice = orderPrice / Point;
            }
            else {
                Alert("佈局 Sell 單豆子發生錯誤: " + CompileErrorMessage(GetLastError()));
            }
        }
        PrintFormat("Total SELL lots=%.2f, distance=%.0f", totalSellLots, firstSellPrice - lastSellPrice);
    }
}