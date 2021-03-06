#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.01"
#property description "根據未平倉單的平均成本, 重新計算停利點位"
#property strict
#property script_show_inputs

//--- input parameters
input bool RESET_BUY_ORDERS  = true;    //重新計算 Buy 單停利價格
input bool RESET_SELL_ORDERS = true;    //重新計算 Sell 單停利價格
input int  TAKE_PROFIT_POINT = 50;      //獲利點數


void OnStart() {
    double buyAvgPrice = 0;
    double buyTotalLots = 0;
    double buyTotalCost = 0;
    double sellAvgPrice = 0;
    double sellTotalLots = 0;
    double sellTotalCost = 0;
    
    int openOrders = OrdersTotal();
    
    for(int i = 0; i < openOrders; i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderType() == OP_BUY) {
                buyTotalCost += OrderOpenPrice() * OrderLots();
                buyTotalLots += OrderLots();
            }

            if(OrderType() == OP_SELL) {
                sellTotalCost += OrderOpenPrice() * OrderLots();
                sellTotalLots += OrderLots();
            }
        }
    }
    
    if(buyTotalLots > 0) buyAvgPrice = buyTotalCost / buyTotalLots;
    if(sellTotalLots > 0) sellAvgPrice = sellTotalCost / sellTotalLots;
    
    //Print("Buy avg: " + buyAvgPrice);
    //Print("Sell avg: " + sellAvgPrice);
    double tpPoint = TAKE_PROFIT_POINT * Point;
    if(RESET_BUY_ORDERS && buyAvgPrice > 0)  ResetTakeProfit(OP_BUY, NormalizeDouble(buyAvgPrice + tpPoint, Digits));
    if(RESET_SELL_ORDERS && sellAvgPrice > 0)  ResetTakeProfit(OP_SELL, NormalizeDouble(sellAvgPrice - tpPoint, Digits));
}

void ResetTakeProfit(int orderType, double tpPrice) {
    int openOrders = OrdersTotal();

    for(int i = 0; i < openOrders; i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderType() == orderType) {
                //Print("Modifying TP of ticket " + OrderTicket() + " to " + tpPrice);
                if(!OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tpPrice, OrderExpiration()))
                   Alert("變更交易單 " + (string)OrderTicket() + " 的停利點失敗: " + (string)GetLastError());
            }
        }
    }

}