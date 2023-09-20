#include <assert.h>
#include <omp.h>
#include <stdio.h>

int main(void) {
  // setbuf(stdout, NULL);
  // printf("Is%s initial device\n", omp_is_initial_device() ? "" : " not");
  // printf("Initial device: %d\n", omp_get_initial_device());

  // printf("got %d devices\n", omp_get_num_devices());
  assert(omp_get_num_devices() > 0 && "need at least 1 devices");

  const int dev_A_num = 0;

  assert(dev_A_num != omp_get_initial_device() &&
         "device A should not be the initial device");

  const char *payloadSizeStr = getenv("PAYLOAD_SIZE");
  assert(payloadSizeStr != NULL &&
         "PAYLOAD_SIZE environment variable is not defined");

  float payloadSize = strtof(payloadSizeStr, NULL);
  payloadSize = payloadSize * 1024 * 1024;
  const long long unsigned int bytes = (long long unsigned int)payloadSize;
  const long long unsigned int N = bytes / sizeof(int);
  int *A;
  A = (int *)malloc(N * sizeof(int));

  // initialize host data
  for (int i = 0; i < N; ++i) {
    A[i] = i;
  }

  // cron start here
  double start = omp_get_wtime();

#pragma omp target enter data map(to : A[ : N]) device(dev_A_num)

#pragma omp target exit data map(delete : A[ : N]) device(dev_A_num)
  double end = omp_get_wtime();

  printf("Time: %f\n", end - start); // plot this value

free(A);

return 0;
}