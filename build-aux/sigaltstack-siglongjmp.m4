# sigaltstack-siglongjmp.m4 serial 3 (libsigsegv-2.4)
dnl Copyright (C) 2002-2003, 2006 Bruno Haible <bruno@clisp.org>
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl How to siglongjmp out of a signal handler, in such a way that the
dnl alternate signal stack remains functional.
dnl SV_TRY_LEAVE_HANDLER_SIGLONGJMP(KIND, CACHESYMBOL, KNOWN-SYSTEMS,
dnl                                 INCLUDES, RESETCODE)
AC_DEFUN([SV_TRY_LEAVE_HANDLER_SIGLONGJMP],
[
  AC_REQUIRE([AC_PROG_CC])
  AC_REQUIRE([AC_CANONICAL_HOST])

  AC_CACHE_CHECK([whether a signal handler can be left through siglongjmp$1], [$2], [
    AC_RUN_IFELSE([
      AC_LANG_SOURCE([[
#include <stdlib.h>
#include <signal.h>
#include <setjmp.h>
$4
#if HAVE_SETRLIMIT
# include <sys/types.h>
# include <sys/time.h>
# include <sys/resource.h>
#endif
sigjmp_buf mainloop;
int pass = 0;
void stackoverflow_handler (int sig)
{
  pass++;
  { $5 }
  siglongjmp (mainloop, pass);
}
volatile int * recurse_1 (volatile int n, volatile int *p)
{
  if (n >= 0)
    *recurse_1 (n + 1, p) += n;
  return p;
}
volatile int recurse (volatile int n)
{
  int sum = 0;
  return *recurse_1 (n, &sum);
}
char mystack[16384];
int main ()
{
  stack_t altstack;
  struct sigaction action;
#ifdef __BEOS__
  /* On BeOS, this would hang, burning CPU time.  Better fail than hang.  */
  exit (1);
#endif
#if defined HAVE_SETRLIMIT && defined RLIMIT_STACK
  /* Before starting the endless recursion, try to be friendly to the user's
     machine.  On some Linux 2.2.x systems, there is no stack limit for user
     processes at all.  We don't want to kill such systems.  */
  struct rlimit rl;
  rl.rlim_cur = rl.rlim_max = 0x100000; /* 1 MB */
  setrlimit (RLIMIT_STACK, &rl);
#endif
  /* Install the alternate stack.  */
  altstack.ss_sp = mystack;
  altstack.ss_size = sizeof (mystack);
  altstack.ss_flags = 0; /* no SS_DISABLE */
  if (sigaltstack (&altstack, NULL) < 0)
    exit (1);
  /* Install the SIGSEGV handler.  */
  sigemptyset (&action.sa_mask);
  action.sa_handler = &stackoverflow_handler;
  action.sa_flags = SA_ONSTACK;
  sigaction (SIGSEGV, &action, (struct sigaction *) NULL);
  sigaction (SIGBUS, &action, (struct sigaction *) NULL);
  /* Provoke two stack overflows in a row.  */
  if (sigsetjmp (mainloop, 1) < 2)
    {
      recurse (0);
      exit (2);
    }
  exit (0);
}]])],
      [$2=yes],
      [$2=no],
      [case "$host" in
         m4_if([$3], [], [], [[$3]) $2=yes ;;])
         *) $2="guessing no" ;;
       esac
      ])
  ])
])
