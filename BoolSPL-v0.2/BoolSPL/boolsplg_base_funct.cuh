//BoolSPLG base CUDA functions
//System includes.
#include <stdio.h>
#include <iostream>

using namespace std;

//////check CUDA component status
////cudaError_t cudaStatus;
////
////void cudaMallocBoolSPLG(int **d_vec, int sizeBoolean)
////{
////	//@@ Allocate GPU memory here
////	cudaStatus = cudaMalloc((void **)&d_vec, sizeBoolean);
////		if (cudaStatus != cudaSuccess) {
////			fprintf(stderr, "cudaMalloc failed!");
////			exit(EXIT_FAILURE);
////		}
////}
////
////void cudaMemcpyBoolSPLG_HtoD(int *d_vec, int *h_vec, int sizeBoolean)
////{
////	// Copy input vectors from host memory to GPU buffers.
////	cudaStatus = cudaMemcpy(d_vec, h_vec, sizeBoolean, cudaMemcpyHostToDevice);
////		if (cudaStatus != cudaSuccess) {
////			fprintf(stderr, "cudaMemcpy failed!");
////			exit(EXIT_FAILURE);
////		}
////}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Return Most significant bit start from 0
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
unsigned int msb32(unsigned int x)
{
	static const unsigned int bval[] =
	{ 0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4 };

	unsigned int r = 0;
	if (x & 0xFFFF0000) { r += 16 / 1; x >>= 16 / 1; }
	if (x & 0x0000FF00) { r += 16 / 2; x >>= 16 / 2; }
	if (x & 0x000000F0) { r += 16 / 4; x >>= 16 / 4; }
	return (r + bval[x]) - 1;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Check array size
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CheckSize(int size)
{
	unsigned int setSize = msb32(size);

	if (setSize > 21)
	{
		cout << "Library BoolSPLG not support array for n >21;" << endl;
		exit(EXIT_FAILURE);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Check S-box size
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CheckSizeSbox(int size)
{
	unsigned int setSize = msb32(size);

	if (setSize > 21)
	{
		cout << "Library BoolSPLG not support S-box for n >21;" << endl;
		exit(EXIT_FAILURE);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Check array size Bool Bitwise
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CheckSizeBoolBitwise(int size)
{
	unsigned int setSize = msb32(size);

	if (setSize<6 & setSize>27)
	{
		cout << "Library BoolSPLG not support array for n<6 and n>27;" << endl;
		exit(EXIT_FAILURE);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Check array size Sbox Bitwise
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CheckSizeSboxBitwise(int size)
{
	unsigned int setSize = msb32(size);

	if (setSize<6 & setSize>27)
	{
		cout << "Library BoolSPLG not support S-box for n<6 and n>27;" << endl;
		exit(EXIT_FAILURE);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Function: Check array size Sbox Bitwise
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void CheckSizeSboxBitwiseMobius(int size)
{
	unsigned int setSize = msb32(size);

	if (setSize<6 & setSize>14)
	{
		cout << "Library BoolSPLG not support S-box for n<6 and n>14;" << endl;
		cout << "\nIs not implemented this funcionality for S-box size n>14. \nThe output data is to big.\n";
		exit(EXIT_FAILURE);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Set GRID
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
inline void setgrid(int size)
{
	if (size <= BLOCK_SIZE)
	{
		sizethread = size;
		sizeblok = 1;
		sizeblok1 = 1;
	}
	else
	{
		sizethread = BLOCK_SIZE;
		sizeblok = size / BLOCK_SIZE;
		sizeblok1 = sizeblok;

		if (sizeblok>32)
			sizeblok1 = 32;
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Set GRID bitwise
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
inline void setgridBitwise(int NumInt) 
{
	if (NumInt <= BLOCK_SIZE)
	{
		sizethread = NumInt;
		sizeblok = 1;
		sizeblok1 = 1;
		

		if (NumInt < 32)
		{
			sizefor = NumInt;
			sizefor1 = 32;
		}
		else
		{
			sizefor = 32;
			sizefor1 = NumInt;
		}
	}

	else
	{
		sizethread = BLOCK_SIZE;
		sizeblok = NumInt / BLOCK_SIZE;
		sizeblok1 = sizeblok;

		if (sizeblok>32)
			sizeblok1 = 32;
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//CPU function for set TT in 64 bit int variables
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void BinVecToDec(int size, int *Bin_Vec, unsigned long long int *NumIntVec, int NumInt)
{
	unsigned long long int decimal = 0, sum = 0, bin, counterBin = 0;
	int set;
	for (int i = 0; i<NumInt; i++)
	{
		decimal = 0, sum = 0, bin, counterBin = 0;
		set = i*size;
		//cout << "Set:" << set ;
		for (int j = ((size - 1) + set); j >= (0 + set); j--)
		{
			bin = Bin_Vec[j];
			decimal = bin << counterBin;
			counterBin++;
			sum = sum + decimal;
		}
		NumIntVec[i] = sum;
		//cout << "Number:"<< sum << " ";
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//CPU function for set ANF from NumIntVector
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void DecVecToBin(int NumOfBits, int *Bin_Vec, unsigned long long int *NumIntVec, int NumInt)
{
	unsigned long long int number = 0, k=0;
	int c, ii = 0;

	for (int i = 0; i<NumInt; i++)
	{
		number = NumIntVec[i];

		for (c = NumOfBits - 1; c >= 0; c--)
		{
			k = number >> c;

			if (k & 1)
			{
				Bin_Vec[ii] = 1;
				//cout << Bin_Vec[ii] << " ";
				ii++;
			}
			else
			{
				Bin_Vec[ii] = 0;
				//cout << Bin_Vec[ii] << " ";
				ii++;
			}
		}
		//cout << "Number:"<< sum << "\n";
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//CPU computing component function (CF) of S-box function - One CF is save in array
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void GenTTComponentFuncVec(int j, int *SboxElemet, int *CPU_STT, int sizeSbox)
{
	unsigned int ones = 0, logI, element;

	for (int i = 0; i<sizeSbox; i++)
	{
		logI = SboxElemet[i] & j;
		// ones = _mm_popcnt_u32(SboxElemet[i]);
		ones = _mm_popcnt_u32(logI);
		//cout << ones << " ";
		// cout << logI << " ";
		if (ones % 2 == 0)
			element = 0;
		else
			element = 1;

		//		cout << element << ", ";

		CPU_STT[i] = element;
	}
	//	cout <<"\n";
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//CPU computing component function (CF) of S-box function - all CF are save in one array
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
void GenTTComponentFunc(int j, int *SboxElemet, int *CPU_STT, int sizeSbox)
{
	unsigned int ones = 0, logI, element;

	for (int i = 0; i<sizeSbox; i++)
	{
		logI = SboxElemet[i] & j;
		// ones = _mm_popcnt_u32(SboxElemet[i]);
		ones = _mm_popcnt_u32(logI);
		//cout << ones << " ";
		// cout << logI << " ";
		if (ones % 2 == 0)
			element = 0;
		else
			element = 1;

		//cout << element << ", ";

		CPU_STT[j*sizeSbox + i] = element;
	}
	//cout << "\n";
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
