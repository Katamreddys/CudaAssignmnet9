#include <iostream>
#include <chrono>

__global__ void polynomial_expansion (float* poly,int degree,int n,float* array) 
{
  int INX=blockIdx.x*blockDim.x+threadIdx.x;
  if(INX<n)
    {
    float val=0.0;
      float exp=1.0;
      for(int x=0;x<=degree;++x)
      {
        val+=exp*poly[x];
        exp*=array[INX];
      }
      array[INX]=val;
    }
}

int main(int argc, char* argv[]) 
{
    if(argc<3) 
    {
      std::cerr<<"usage: "<<argv[0]<<" n degree"<<std::endl;
      return -1;
    }

  int n=atoi(argv[1]); 
  int degree=atoi(argv[2]);
  int nbiter=1;
    float* array=new float[n];
    float* poly=new float[degree+1];
    for(int i=0;i<n;++i)
  {
      array[i]=1.;
  }

    for(int i=0;i<degree+1;++i)
  {
      poly[i]=1.;
  }

    float *DArr,*PArr;

  //start calculating time
    std::chrono::time_point<std::chrono::system_clock> start_time,end_time;
    start_time = std::chrono::system_clock::now();

    cudaMalloc(&DArr,n*sizeof(float));
    cudaMalloc(&PArr,(degree+1)*sizeof(float));

    cudaMemcpy(DArr,array,n*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(PArr,poly,(degree+1)*sizeof(float),cudaMemcpyHostToDevice);

    polynomial_expansion<<<(n+255)/256, 256>>>(PArr,degree,n,DArr);
    cudaMemcpy(array,DArr,n*sizeof(float),cudaMemcpyDeviceToHost);

    cudaFree(DArr);
    cudaFree(PArr);

    cudaDeviceSynchronize();
  {
        bool correct=true;
        int ind;
    for(int i=0;i<n;++i) 
    {
      if(fabs(array[i]-(degree+1))>0.01) 
      {
        correct=false;
        ind=i;
      }
    }
        if(!correct)
        std::cerr<<"Result is incorrect. In particular array["<<ind<<"] should be "<<degree+1<<" not "<< array[ind]<<std::endl;
  }
  // calculate and print time
    end_time=std::chrono::system_clock::now();
    std::chrono::duration<double> elapsed_time=(end_time-start_time)/nbiter;
    std::cout<<n<<" "<<degree<<" "<<elapsed_time.count()<<std::endl;
  
  // free arrays
    delete[] array;
    delete[] poly;

    return 0;
}

