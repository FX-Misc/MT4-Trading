#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.00"
#property description "取消所有的預掛單"
#property strict
#property script_show_inputs

#import "TimUtil.ex4" 
void DeletePendingOrders(int& orders[]);
bool CollectOrderTickets(string symbol, int orderType, int& tickets[], int magicNumber = 930214);
#import

//--- input parameters
input bool CANCEL_PENDING_BUY  = false;      //是否取消預掛 Buy 單
input bool CANCEL_PENDING_SELL = false;      //是否取消預掛 Sell 單

const int MAGIC_NUMBER        = 930214;

void OnStart() {
    if(CANCEL_PENDING_BUY) {
        int orders[];
        CollectOrderTickets(Symbol(), OP_BUYSTOP, orders, MAGIC_NUMBER);
        DeletePendingOrders(orders);
    }

    if(CANCEL_PENDING_SELL) {
        int orders[];
        CollectOrderTickets(Symbol(), OP_SELLSTOP, orders, MAGIC_NUMBER);
        DeletePendingOrders(orders);
    }
}