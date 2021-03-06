#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.02"
#property description "假裝犬類下單"
#property script_show_inputs
#property strict

#import "stdlib.ex4" 
string ErrorDescription(int error_code); 
#import

enum enumOrderType {
    BUY        = OP_BUY,       //Buy
    SELL       = OP_SELL,      //Sell
    BUY_LIMIT  = OP_BUYLIMIT,  //Buy Limit
    SELL_LIMIT = OP_SELLLIMIT, //Sell Limit
    BUY_STOP   = OP_BUYSTOP,   //Buy Stop
    SELL_STOP  = OP_SELLSTOP   //Sell Stop
};

enum enumMagicNumber {
    NONE     = 0,         //不指定
    SingleSD = 88881000,  //牧羊犬
    DoubleSD = 88882000,  //雙頭犬
    BullSD   = 88882000,  //鬥牛犬
    FlashSD  = 88883000,  //閃電犬
    SuperSD  = 88886000   //超級犬
};

//input int    ORD_TYPE     = 0;          //交易類型: 0=B 1=S 2=BL 3=SL 4=BS 5=SS
input enumMagicNumber MAGIC_NUMBER = NONE;   //要模擬的程式
input enumOrderType   ORD_TYPE     = BUY;    //交易類型
input int             ORD_PRICE    = 0;      //價格 (0 = 市價, 不需小數點, e.g 110987 = 1.10987)
input double          ORD_LOTS     = 0;      //手數
input string          ORD_COMMENT  = "";     //附註


void OnStart() {
    double price = ORD_PRICE * Point;
    int orderType = (int)ORD_TYPE;
    if(orderType == OP_BUY && ORD_PRICE == 0)  price = Ask;
    if(orderType == OP_SELL && ORD_PRICE == 0)  price = Bid;
    int magicNumber = (int)MAGIC_NUMBER;
    
    int ticket = OrderSend(Symbol(), orderType, ORD_LOTS, price, 0, 0, 0, ORD_COMMENT, MAGIC_NUMBER, 0, (orderType % 2 == 0)? clrBlue : clrRed);
    if(ticket < 0)
        Alert("下單發生錯誤: " + CompileErrorMessage(GetLastError()));
}


//組合錯誤訊息
string CompileErrorMessage(int errorCode) {
    return (string)errorCode + " - " + ErrorDescription(errorCode);
}
