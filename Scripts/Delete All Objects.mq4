#property copyright "Copyright 2016, Tim Hsu"
#property link      ""
#property version   "1.00"
#property description "刪除圖表中所有的物件, 例如: 線條, 文字框 ... 等等"
#property strict

static long gs_chartId = ChartID();

void OnStart() {
    ObjectsDeleteAll(gs_chartId);
}
