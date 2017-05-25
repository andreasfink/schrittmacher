//
//  main.m
//  schrittmacher
//
//  Created by Andreas Fink on 20/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

#import "AppDelegate.h"
#import "version.h"

#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <sys/wait.h>
#include <sysexits.h>
#include <unistd.h>
#include <limits.h>

static int parachute_launch(int argc2, char *argv2[]);
static void parachute_init_signals(int child);
static void parachute_sig_handler(int signum);

static int child_actions_init = 0;
static struct sigaction child_actions[32];
static pid_t child_pid = 0;
static int parachute_shutdown = 0;

int     global_argc;
char    **global_argv;

int     global_argc2;
char    **global_argv2=NULL;
BOOL must_quit = NO;
int signal_sigint = 0;
int signal_sigpipe = 0;
int signal_sighup = 0;
int signal_sigterm = 0;
int sig= 0;
BOOL isRunning = YES;
int global_license_verbosity = 0;
int g_daemonize=0;
int g_parachute=0;
int g_use_version2_router = 1;
int g_make_pid = 0;
int g_tlog_enable = 0;
const char *g_pidfile = NULL;

static void signal_handler(int signum);
static void setup_signal_handlers(void);
static void signal_SIGHUP(void);
static void	signal_SIGINT(void);
static void	signal_SIGPIPE(void);
static void	signal_SIGTERM(void);
FILE *tlog = NULL;

AppDelegate *_gad = nil;
NSString *configFile = nil;

void write_pid_file(int create,const char *filename);
void open_tlog(void);

int main(int argc, char *argv[])
{
    
    const char	*config_files[] = { "schrittmacher.conf", "/etc/schrittmacher/schrittmacher.conf",NULL };
    const char *gConfigFile=NULL;

#if defined(LINUX_BUNDLE)
    extern char		**environ;
    [NSProcessInfo initializeWithArguments: (char**)argv
                                     count: argc
                               environment: environ];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *className = [infoDict objectForKey: @"NSPrincipalClass"];
    //    Class *appClass = NSClassFromString(className);
#endif
    
    int i;
    FILE *f;
    NSRunLoop *runLoop = NULL;
    AppDelegate *appdel;
    
    @autoreleasepool
    {
        
        [NSBundle initialize];
        [NSFileManager initialize];
        
        global_argc = argc;
        global_argv = argv;
        global_argc2 = argc;
        size_t size_of_argv2 = (argc*1 + 10 ) * sizeof(char *);
        global_argv2 = malloc(size_of_argv2);
        memset(global_argv2,0x00,size_of_argv2);
        global_argv2[0] = global_argv[0];
        global_argc2 = 1;

        for(i=1;i<argc;i++)
        {
            char *option = argv[i];
            
            if(0==strcmp(option,"--daemonize"))
            {
                g_daemonize = 1;
            }

            if(0==strcmp(option,"--config-file"))
            {
                i++;
                if(i<argc)
                {
                    gConfigFile = argv[i];
                    global_argv2[global_argc2++] = "--config-file";
                    global_argv2[global_argc2++] = argv[i];

                }
            }

            else if(0==strcmp(option,"--make-pidfile"))
            {
                g_make_pid = 1;
            }

            else if(0==strcmp(option,"--pidfile"))
            {
                i++;
                if(i<argc)
                {
                    g_pidfile = argv[i];
                }
            }
            else if(0==strcmp(option,"--parachute"))
            {
                g_parachute = 1;
                global_argv2[global_argc2++] = "--launched-using-parachute";
                
            }
            else if(0==strcmp(option,"--launched-using-parachute"))
            {
                g_parachute = 0;
            }
            else if(0==strcmp(option,"-NSDocumentRevisionsDebugMode"))
            {
                /* ignore following parameter too */
                i++;
            }
            else if(strcmp(option,"--version")==0)
            {
                NSLog(@"%s Version %s",argv[0],VERSION);
                exit(-1);
            }
            else if(strncmp(option,"--",2)==0)
            {
                NSLog(@"Unknown option %s",option);
                exit(-1);
            }
            else
            {
                if(gConfigFile==NULL)
                {
                    gConfigFile = argv[i];
                    global_argv2[global_argc2++] = "--config-file";
                    global_argv2[global_argc2++] = argv[i];
                }
            }
        }
    }
    if(g_parachute==1)
    {
        parachute_launch(global_argc2,global_argv2);
    }
    else
    {
        write_pid_file(g_make_pid,g_pidfile);
        @autoreleasepool
        {
            runLoop = [NSRunLoop currentRunLoop];
            if(runLoop==NULL)
            {
                NSLog(@"No current run loop");
                exit(-1);
            }
            [NSOperationQueue mainQueue];
            setup_signal_handlers();
            
            appdel = [[AppDelegate alloc]init];

            if(gConfigFile==NULL)
            {
                for(i=0;i<(sizeof(config_files) / sizeof (char *));i++)
                {
                    f = fopen(config_files[i],"r");
                    if(f)
                    {
                        fclose(f);
                        gConfigFile = config_files[i];
                        configFile = @(config_files[i]);
                        continue;
                    }
                }
            }
            if(gConfigFile==NULL)
            {
                fprintf(stderr,"No config file found");
                exit(-1);
            }
            
            configFile =@(gConfigFile);
            
            NSDictionary *notificationObject = @{ @"fileName" : configFile};
            NSNotification *notification = [NSNotification notificationWithName:@"config file name" object:notificationObject];
            [appdel applicationDidFinishLaunching:notification];
            must_quit=NO;
        }
        while (must_quit==NO)
        {
            @autoreleasepool
            {
                isRunning = [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                if(sig>0)
                {
                    if(signal_sigpipe>0)
                    {
                        signal_SIGPIPE();
                    }
                    if(signal_sighup>0)
                    {
                        signal_SIGHUP();
                    }
                    if(signal_sigint>0)
                    {
                        signal_SIGINT();
                    }
                    if(signal_sigterm>0)
                    {
                        signal_SIGTERM();
                    }
                }
            }
        }
        NSLog(@"terminating");
    }
}

static void	signal_SIGPIPE(void)
{
    signal_sigpipe--;
    sig--;
    NSLog(@"SIGPIPE received, ignoring...");
}

static void signal_SIGHUP(void)
{
    signal_sighup--;
    sig--;
    NSLog(@"SIGHUP received.");
}

static void	signal_SIGINT(void)
{
    sig--;
    signal_sigint=0;
    if (must_quit == 0)
    {
        NSLog(@"SIGINT received, aborting program...");
        must_quit = 1;
    }
    else
    {
        NSLog(@"SIGINT received again, force quitting program...");
        must_quit = 2;
        exit(0);
    }
}

static void	signal_SIGTERM(void)
{
    sig--;
    signal_sigterm=0;
    if (must_quit == 0)
    {
        NSLog(@"SIGTERM received, aborting program...");
        must_quit = 1;
    }
    else
    {
        NSLog(@"SIGTERM received again, force quitting program...");
        must_quit = 2;
        exit(0);
    }
}


static void signal_handler(int signum)
{
    /* On some implementations (i.e. linuxthreads), signals are delivered
     * to all threads.  We only want to handle each signal once for the
     * entire box, and we let the gwthread wrapper take care of choosing
     * one. DONT CALL debug(), info() etc. here or you might create a deadlock
     */
    sig++;
    if (signum == SIGINT)
    {
        signal_sigint++;
    }
    else if (signum == SIGTERM)
    {
        signal_sigterm++;
    }
    else if (signum == SIGPIPE)
    {
        signal_sigpipe++;
    }
    else if (signum == SIGHUP)
    {
        signal_sighup++;
    }
    else if( signum == SIGSEGV)
    {
        NSString *bt = UMBacktrace(NULL,0);
        const char *c = bt.UTF8String;
        if(c)
        {
            size_t len = strlen(c);
            FILE *f = fopen("/tmp/crashlog.txt","w+");
            if(f)
            {
                fwrite(c,len,1,f);
                fclose(f);
            }
        }
        exit(-1);
    }
}


static void setup_signal_handlers(void)
{
    struct sigaction act;
    
    act.sa_handler = signal_handler;
    sigemptyset(&act.sa_mask);
    act.sa_flags = 0;
    sigaction(SIGINT, &act, NULL);
    sigaction(SIGHUP, &act, NULL);
    sigaction(SIGPIPE, &act, NULL);
    sigaction(SIGTERM, &act, NULL);
    sigaction(SIGSEGV, &act,NULL);
}

static int parachute_launch(int argc2, char *argv2[])
{
    time_t last_start = 0;
    long respawn_count = 0;
    int status;
    
    parachute_init_signals(0);
    
    for (;;)
    {
        if (respawn_count > 0 && difftime(time(NULL), last_start) < 10)
        {
            NSLog(@"Child process died too fast, disabling for 30 sec.");
            sleep(30.0);
        }
        if (!(child_pid = fork()))
        { /* child process */
            int i;
            
            parachute_init_signals(1); /* reset sighandlers */
            int ret =  execvp(argv2[0], argv2);
            if(ret < 0)
            {
                int eno = errno;
                fprintf(stderr,"execvp returned %d. errno=%d\n",ret,eno);
                fprintf(stderr,"called  execvp() like this:\n");
                for(i=0;argv2[i]!=NULL;i++)
                {
                    fprintf(stderr," argv[%i]=%s\n",i,argv2[i]);
                }
            }
            return ret;
        }
        else if (child_pid < 0)
        {
            NSLog(@"Could not start child process! Will retry in 5 sec.");
            sleep(5.0);
            continue;
        }
        else
        { /* father process */
            write_pid_file(g_make_pid,g_pidfile);
            time(&last_start);
            NSLog(@"Child process with PID (%ld) started.", (long) child_pid);
            do
            {
                pid_t p = waitpid(child_pid, &status, 0);
                int eno = errno;
                if (p == child_pid)
                {
                    /* check here why child terminated */
                    /* if (WIFEXITED(status) && WEXITSTATUS(status) == 0)
                     {
                     NSLog(@"Child process exited gracefully, exit...");
                     exit(0);
                     }
                     else */
                    if (WIFEXITED(status))
                    {
                        NSLog(@"Caught child PID (%ld) which died with return code %d",
                              (long) child_pid, WEXITSTATUS(status));
                        child_pid = -1;
                        sleep(2.0);
                    }
                    else if (WIFSIGNALED(status))
                    {
                        NSLog(@"Caught child PID (%ld) which died due to signal %d",
                              (long) child_pid, WTERMSIG(status));
                        child_pid = -1;
                    }
                }
                else if (eno != EINTR)
                {
                    NSLog(@"Error while waiting of child process.");
                }
            }
            while(child_pid > 0);
            
            if (parachute_shutdown)
            {
                /* may only happens if child process crashed while shutdown */
                NSLog(@"Child process crashed while shutdown. Exiting due to signal...");
                exit(WIFEXITED(status) ? WEXITSTATUS(status) : EX_OK);
            }
            
            /* check whether it's panic while start */
            if (respawn_count == 0 && difftime(time(NULL), last_start) < 2)
            {
                NSLog(@"Child process crashed while starting. Exiting...");
                exit(WIFEXITED(status) ? WEXITSTATUS(status) : EX_USAGE);
            }
            respawn_count++;
            /* sleep a while to get e.g. sockets released */
            sleep(5);
        }
    }
    return 0;
}

static void parachute_init_signals(int child)
{
    struct sigaction sa;
    
    if (child_actions_init && child)
    {
        sigaction(SIGTERM, &child_actions[SIGTERM], NULL);
        sigaction(SIGQUIT, &child_actions[SIGQUIT], NULL);
        sigaction(SIGINT,  &child_actions[SIGINT], NULL);
        sigaction(SIGABRT, &child_actions[SIGABRT], NULL);
        sigaction(SIGHUP,  &child_actions[SIGHUP], NULL);
        sigaction(SIGALRM, &child_actions[SIGALRM], NULL);
        sigaction(SIGUSR1, &child_actions[SIGUSR1], NULL);
        sigaction(SIGUSR2, &child_actions[SIGUSR2], NULL);
        sigaction(SIGPIPE, &child_actions[SIGPIPE], NULL);
    }
    else if (!child && !child_actions_init)
    {
        sa.sa_flags = 0;
        sigemptyset(&sa.sa_mask);
        sa.sa_handler = parachute_sig_handler;
        sigaction(SIGTERM, &sa, &child_actions[SIGTERM]);
        sigaction(SIGQUIT, &sa, &child_actions[SIGQUIT]);
        sigaction(SIGINT,  &sa, &child_actions[SIGINT]);
        sigaction(SIGABRT, &sa, &child_actions[SIGABRT]);
        sigaction(SIGHUP,  &sa, &child_actions[SIGHUP]);
        sigaction(SIGALRM, &sa, &child_actions[SIGALRM]);
        sigaction(SIGUSR1, &sa, &child_actions[SIGUSR1]);
        sigaction(SIGUSR2, &sa, &child_actions[SIGUSR2]);
        sa.sa_handler = SIG_IGN;
        sigaction(SIGPIPE, &sa, &child_actions[SIGPIPE]);
        sigaction(SIGTTOU, &sa, NULL);
        sigaction(SIGTTIN, &sa, NULL);
        sigaction(SIGTSTP, &sa, NULL);
        child_actions_init = 1;
    }
    else
    {
        NSLog(@"Child process signal handlers not initialized before.");
        exit(0);
    }
}

static void parachute_sig_handler(int signum)
{
    NSLog(@"Signal %d received, forward to child pid (%ld)", signum, (long) child_pid);
    
    /* we do not handle any signal, just forward these to child process */
    if (child_pid != -1 && getpid() != child_pid)
        kill(child_pid, signum);
    
    /* if signal received and no child there, terminating */
    switch(signum)
    {
        case SIGTERM:
        case SIGINT:
        case SIGABRT:
            if (child_pid == -1)
            {
                exit(EX_OK);
            }
            else
            {
                parachute_shutdown = 1;
            }
    }
}


void write_pid_file(int create,const char *filename)
{
    if(filename)
    {
        FILE *f=NULL;
        if(create)
        {
            f=fopen(g_pidfile,"w");
        }
        else
        {
            f=fopen(g_pidfile,"r+");
        }
        if(f)
        {
            fprintf(f,"%d\n",getpid());
            fclose(f);
        }
    }
}

