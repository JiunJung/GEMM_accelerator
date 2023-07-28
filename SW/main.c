#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include <stdlib.h>

#define AXI_DATA_BYTE 4

#define IDLE 1
#define RUN 1 << 1
#define DONE 1 << 2

#define CTRL_REG 0
#define STATUS_REG 1
#define MEM0_ADDR_REG 2
#define MEM0_DATA_REG 3
#define MEM1_ADDR_REG 4
#define MEM1_DATA_REG 5
#define RESULT_0_REG 6
#define RESULT_1_REG 7
#define RESULT_2_REG 8
#define RESULT_3_REG 9

#define MEM_DEPTH 4096

unsigned int* data_gen(int data_num) {
    unsigned int* data_node = (unsigned int*)malloc(sizeof(unsigned int) * data_num);
    return data_node;
}

// Function to print an integer in binary form
void printBinary(unsigned int num) {
    for (int bit = sizeof(num) * 8 - 1; bit >= 0; bit--) {
        printf("%d", (num >> bit) & 1);
    }
    printf("\n");
}

int main() {
	int i = 0;
    int j = 0;
    int input_num = 0;
    unsigned int* input_node;
    unsigned int* weights;
    int weights_row[4] = {0,};
	int check_togo = 0;
	int read_data = 0;
	unsigned int result[4];
	int again = 0;

    while (1) {
    	printf("This is a GEMM accelerator please enter your inputs and weights. \n");
    	printf("(1 x n) X (n x 4) = (1 x 4) \n");
    	printf("\n");

		//an input value should 0~255
		while (input_num > 4096 || input_num < 1) {
			printf("How many inputs do you have : \n");
			scanf("%d", &input_num);
			printf("%d\n", input_num);
			if (input_num > 4096){
				printf("we can't afford it.\n");
			} 
		}

		printf("please enter %d values : \n", input_num);
		input_node = data_gen(input_num);
		weights = data_gen(input_num);

		for (i = 0; i < input_num; i++) {
			scanf("%d", (input_node + i));
			printf("%d \n", *(input_node + i));
		}

		printf("Here are your inputs : \n");

		for (i = 0; i < input_num; i++) {
			printf("%d ", *(input_node + i));
		}

		printf("\n");
		printf("Please enter your weights (weight size : %d x 4) : \n", input_num);

		for (i = 0; i < input_num; i++) {
			weights[i] = 0;
			for (j = 0; j < 4; j++) {
				scanf("%d", &weights_row[j]);
				printf("(%d,%d) : %d \n",i,j,weights_row[j]);
			}
			weights[i] |= weights_row[0]; weights[i] = weights[i] << 8;
			weights[i] |= weights_row[1]; weights[i] = weights[i] << 8;
			weights[i] |= weights_row[2]; weights[i] = weights[i] << 8;
			weights[i] |= weights_row[3];
		}

		printf("Here are your weights : \n");

		for (i = 0; i < input_num; i++) {
			printf("Weight[%d]: \n", i);
			printBinary(weights[i]);
		}
		while(check_togo!=1){
			printf("\n");
			printf("enter 1 to continue : \n");
			scanf("%d", &check_togo);
		}

		Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0)); // init core ctrl reg
		Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear

		for(i=0; i< MEM_DEPTH ; i++){
			if(i<input_num){
				Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), input_node[i]);
			}else{
				Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), (u32)(0x00000000));
			}
		}

		Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM1_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
		for(i=0; i< MEM_DEPTH ; i++){
			if(i<input_num){
				Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM1_DATA_REG*AXI_DATA_BYTE), weights[i]);
			}else{
				Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (MEM1_DATA_REG*AXI_DATA_BYTE), (u32)(0x00000000));
			}
		}

		// check IDLE
		do{
			read_data = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
		} while( (read_data & IDLE) != IDLE);
		Xil_Out32((XPAR_LAB22_MATBI_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(MEM_DEPTH | 0x80000000)); // MSB run
		// wait done
		do{
			read_data = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
		} while( (read_data & DONE) != DONE );

		result[0] = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (RESULT_0_REG*AXI_DATA_BYTE));
		result[1] = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (RESULT_1_REG*AXI_DATA_BYTE));
		result[2] = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (RESULT_2_REG*AXI_DATA_BYTE));
		result[3] = Xil_In32((XPAR_LAB22_MATBI_0_BASEADDR) + (RESULT_3_REG*AXI_DATA_BYTE));

		printf("\n");
		printf("Here are your results! \n");
		for(i=0;i<4;i++){
			printf("output node %d : %d\n",i+1,result[i]);
		}
		printf("\n");
		input_num = 0;
		while(again!=1){
			printf("\n");
			printf("If you want to try again, enter 1 : \n");
			scanf("%d", &again);
		}
		printf("\n");
    }


		free(weights);
		free(input_node);
		return 0;
}
