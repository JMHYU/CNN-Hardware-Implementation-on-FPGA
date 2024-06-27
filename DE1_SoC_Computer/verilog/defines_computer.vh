parameter DATA_LEN 	= 32;		// Data LEN
parameter M 		= 8;				
parameter N 		= 8;				
parameter K 		= 8;

parameter KX 	= 4;	// kernel x
parameter KY 	= 3;	// kernel y
parameter IX 	= 8;	// input x
parameter IY 	= 4;	// input y
parameter OX 	= 5;	// output x = inputx - kernerlx +1
parameter OY 	= 2;	// output y = inputy - kernerly +1

parameter IN 	= 2;	// input number
parameter ICH 	= 3;	// input channel 
parameter OCH 	= 2;	// output channel (= kernerl number)

parameter ADDRESS_SIZE 			= 4;
parameter READ_A_ADDR_OFFSET 	= 4;
parameter READ_B_ADDR_OFFSET 	= 0;
parameter READ_C_ADDR_OFFSET 	= 0;
parameter WRITE_B_ADDR_OFFSET 	= 12;
parameter WRITE_C_ADDR_OFFSET 	= 12;

parameter ROW_SIZE 		= (DATA_LEN*K);
parameter INPUT_SIZE	= (DATA_LEN*IN*ICH*IY*IX);
parameter WEIGHT_SIZE	= (DATA_LEN*OCH*ICH*KY*KX);
parameter OUTPUT_SIZE	= (DATA_LEN*IN*OCH*OY*OX);


// latency의 minimum 값들 (clock cycle을 최소값으로 얻을 수 있는)
parameter LATENCY_kernel   = 2;                                     //cnn_kernel
parameter LATENCY_acc_ci   = (LATENCY_kernel+1)*(OX*OY) + 3;        //cnn_acc_ci
parameter LATENCY_core     = (LATENCY_acc_ci+1)*(OCH)   + 2;        //cnn_core
parameter LATENCY_topCore  = (LATENCY_core  +1)*(IN)    + 2;        //cnn_topCore

/*
1. 데이터 읽고 쓰는건 다 A, B, C로 기술
2. Write 할때 한 row에 하나씩

*/