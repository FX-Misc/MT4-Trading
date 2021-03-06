#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.00"
#property description "搜尋指定根數 K 棒的高低點, 繪製高低及四分位線"
#property description "可手動調整高低線位置後, 重新計算並繪製四分位線"
#property strict
#property script_show_inputs

input int  K_BARS_RANGE = 90;     //要搜尋的 K 棒數

const string HIGH_LINE_NAME = "HIGH_LINE";
const string LOW_LINE_NAME  = "LOW_LINE";
const string Q1_LINE_NAME   = "Q1_LINE";
const string Q2_LINE_NAME   = "Q2_LINE";
const string Q3_LINE_NAME   = "Q3_LINE";

static long gs_chartId = ChartID();

void OnStart() {
    double high = 0;
    double low  = 9999;
    double q1   = 0;
    double q2   = 0;
    double q3   = 0;

    if(ObjectFind(gs_chartId, HIGH_LINE_NAME) == 0 && ObjectFind(gs_chartId, LOW_LINE_NAME) == 0) {
        high = ObjectGetDouble(gs_chartId, HIGH_LINE_NAME, OBJPROP_PRICE);
        low = ObjectGetDouble(gs_chartId, LOW_LINE_NAME, OBJPROP_PRICE);
    } else {
        for(int i = 1; i <= K_BARS_RANGE; i++) {
            if(High[i] > high)   high = High[i];
            if(Low[i] < low)   low = Low[i];
        }
    }

    q2 = (high + low) / 2;
    q1 = (q2 + low) / 2;
    q3 = (high + q2) / 2;

    ObjectsDeleteAll(gs_chartId);
    DrawLine(LOW_LINE_NAME, low, clrRed);
    DrawLine(Q1_LINE_NAME, q1, clrGold);
    DrawLine(Q2_LINE_NAME, q2, clrDarkViolet);
    DrawLine(Q3_LINE_NAME, q3, clrGold);
    DrawLine(HIGH_LINE_NAME, high, clrRed);
}


void DrawLine(string lineName, double linePrice, long lineColor) {
    ObjectCreate(gs_chartId, lineName, OBJ_HLINE, 0, TimeCurrent(), linePrice);
    ObjectSetInteger(gs_chartId, lineName, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(gs_chartId, lineName, OBJPROP_WIDTH, 2);
}