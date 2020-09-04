
#include <math.h>
#include <stdio.h>

#define openacc_testN 4096
#define openacc_testM 4096

int main()
{
    int i,j;
    int m = openacc_testM, n = openacc_testN;
    float error = 1, tol = 0.000000001;
    int iter = 0, iter_max = 1000;

    float Anew[openacc_testN][openacc_testM];
    float A[openacc_testN][openacc_testM];

    Anew[1][1] = 0;

    while (iter < iter_max)
    {
        error = 0.f;

#pragma omp parallel for shared(m, n, Anew, A)
#pragma acc kernels
        for (j = 1; j < openacc_testN - 1; j++)
        {
            for (i = 1; i < openacc_testM - 1; i++)
            {
                Anew[j][i] = 0.25f * (A[j][i + 1] + A[j][i - 1] + A[j - 1][i] + A[j + 1][i]);
                error = fmaxf(error, fabsf(Anew[j][i] - A[j][i]));
            }
        }

#pragma omp parallel for shared(m, n, Anew, A)
#pragma acc kernels
        for (j = 1; j < openacc_testN - 1; j++)
        {
            for (i = 1; i < openacc_testM - 1; i++)
            {
                A[j][i] = Anew[j][i];
            }
        }

        if (iter % 100 == 0)
            printf("%5d, %0.6f\n", iter, error);

        iter++;
    }

    printf("%5d, %0.6f\n", iter, error);
    return 0;
}
