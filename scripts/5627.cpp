//
// Author: greg zakharov
//
#include <windows.h>
#include <stdio.h>

#define SystemTimeInformation 3
#define NT_SUCCESS(Status) ((NTSTATUS)(Status) >= 0)

typedef struct _SYSTEM_TIME_INFORMATION {
    LARGE_INTEGER liKeBootTime;
    LARGE_INTEGER liKeSystemTime;
    LARGE_INTEGER liExpTimeZoneBias;
    DWORD         dwReserved[2];
} SYSTEM_TIME_INFORMATION;

NTSTATUS (__stdcall *NtQuerySystemInformation)(
    UINT   SystemInformationClass,
    PVOID  SystemInformation,
    ULONG  SystemInformationLength,
    PULONG ReturnLength
);

BOOLEAN (__stdcall *RtlTimeToSecondsSince1970)(
    PLARGE_INTEGER Time,
    PULONG         ElapsedSeconds
);

int main() {
  SYSTEM_TIME_INFORMATION sti;
  FILETIME cur, ft;
  ULONG sec1, sec2, delta, t_s, t_m, t_h, t_d;
  
  if (!(NtQuerySystemInformation = (void *)GetProcAddress(
      GetModuleHandle("ntdll.dll"), "NtQuerySystemInformation"
  ))) {
    printf("Could not find NtQuerySystemInformation entry point.");
    exit(1);
  }
  
  if (!(RtlTimeToSecondsSince1970 = (void *)GetProcAddress(
      GetModuleHandle("ntdll.dll"), "RtlTimeToSecondsSince1970"
  ))) {
    printf("Could not find RtlTimeToSeondsSince1970 entry point.");
    exit(1);
  }
  
  if (NT_SUCCESS(NtQuerySystemInformation(SystemTimeInformation, &sti, sizeof(sti), 0))) {
    ft = *(FILETIME *)&sti.liKeBootTime;
    
    GetSystemTimeAsFileTime(&cur);
    RtlTimeToSecondsSince1970((PLARGE_INTEGER)&cur, &sec1);
    RtlTimeToSecondsSince1970((PLARGE_INTEGER)&ft, &sec2);
    
    delta = sec1 - sec2;
    t_d = delta / 86400;
    t_h = delta / 3600;
    t_m = (delta % 3600) / 60;
    t_s = delta % 60;
    printf("%.2d:%.2d:%.2d up %d day%s", t_h, t_m, t_s, t_d, t_d > 1 ? "s" : "");
  }
  
  return 0;
}
