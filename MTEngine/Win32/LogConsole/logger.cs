using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.IO;
using LogConsole.Appenders;
using System.Diagnostics;
using System.Reflection;

namespace LogConsole
{
    public class logger
    {
        private const int PAD_METHOD_LENGTH = 47;
        public static volatile bool useLogger = true;

#if FULL_DEMO
        public static ushort defaultLogLevel =
           (ushort)LogLevel.FATAL | (ushort)LogLevel.ERROR | (ushort)LogLevel.WARN
           | (ushort)LogLevel.INFO;
#elif DEBUG
        public static ushort defaultLogLevel =
           (ushort)LogLevel.FATAL | (ushort)LogLevel.ERROR
           | (ushort)LogLevel.WARN | (ushort)LogLevel.INFO
           | (ushort)LogLevel.DEBUG | (ushort)LogLevel.CONNECTION
           | (ushort)LogLevel.GUI | (ushort)LogLevel.XML;
           //| (ushort)LogLevel.TRANSAKCJA;
#else
        public static ushort defaultLogLevel =
           (ushort)LogLevel.FATAL | (ushort)LogLevel.ERROR
           | (ushort)LogLevel.WARN | (ushort)LogLevel.INFO
           | (ushort)LogLevel.DEBUG | (ushort)LogLevel.CONNECTION
           | (ushort)LogLevel.GUI; // | (ushort)LogLevel.XML;
           //| (ushort)LogLevel.TRANSAKCJA;
#endif

        public static ushort logLevel = defaultLogLevel; //(ushort)LogLevel.ALL_ON;

        private static List<ILogAppender> logAppenders;

        private static bool logThreadName;
        private static bool logMethodName;

        public static ILogWindowClose logWindowCloseCallback;

        public enum LogLevel : ushort
        {
            ALL_OFF     = 0x0000,
            ALL_ON      = 0xFFFF,
            FATAL       = (1 << 0),
            ERROR       = (1 << 1),
            WARN        = (1 << 2),
            GUI         = (1 << 3),
            INFO        = (1 << 4),
            TRANSAKCJA  = (1 << 5),
            CONNECTION  = (1 << 6),
            DEBUG       = (1 << 7),
            DATABASE    = (1 << 8),
            SQL         = (1 << 9),
            XML         = (1 << 10),
            RES	        = (1 << 11),
            XMPLAYER	= (1 << 12),
            AUDIO	    = (1 << 13),
            TODO		= (1 << 14)
        }

        // constructor for static resources
        static logger()
        {
            useLogger = false;
        }

        public static void Startup(String settingsName)
        {
            LogEngine.Settings.Startup(settingsName);

            logger.logAppenders = new List<ILogAppender>();
            useLogger = true;
            logThreadName = false;
            logMethodName = false;
        }

        public static void SetLogParameters(bool logThreadName, bool logMethodName)
        {
            logger.logThreadName = logThreadName;
            logger.logMethodName = logMethodName;
        }

        public static void Shutdown()
        {
            lock (logger.logAppenders)
            {
                foreach (ILogAppender logAppender in logger.logAppenders)
                {
                    logAppender.Shutdown();
                }
            }
        }

        public static void RegisterAppender(ILogAppender appender)
        {
            lock (logger.logAppenders)
            {
                logger.logAppenders.Add(appender);
            }
        }

        public static void RegisterWindowCloseCallback(ILogWindowClose logWindowCloseCallback)
        {
            logger.logWindowCloseCallback = logWindowCloseCallback;
        }

        public static void ConsoleWindowClose()
        {
            if (logWindowCloseCallback != null)
                logWindowCloseCallback.LogWindowClose();
        }

        public static void SetLogLevel(LogLevel level, bool set)
        {
            if (set)
            {
                logger.logLevel |= (ushort)level;
            }
            else
            {
                logger.logLevel &= (ushort)(~(uint)level);
            }
        }

        public static void SetLogLevel(ushort level)
        {
            logger.logLevel = level;
        }

        public static void SetLogLevelFromSettings(ushort level)
        {
            //logger.logLevel = level;
        }

        public static ushort GetLogLevel()
        {
            return logger.logLevel;
        }

        public static bool IsLogLevelSet(LogLevel level)
        {
            if (((ushort)logger.logLevel & (ushort)level) != 0x0000)
                return true;
            return false;
        }
        
        public static void connection(String message)
        {
            Append(message, LogLevel.CONNECTION, false);
        }

        public static void connection(long connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.CONNECTION, false);
        }

        public static void connection(String userName, String message)
        {
            Append("<" + userName + "> " + message, LogLevel.CONNECTION, false);
        }

        public static void connection(bool previousMethod, String message)
        {
            Append(message, LogLevel.CONNECTION, previousMethod);
        }

        public static void connection(bool previousMethod, long connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.CONNECTION, previousMethod);
        }

        public static void connection(bool previousMethod, String userName, String message)
        {
            Append("<" + userName + "> " + message, LogLevel.CONNECTION, previousMethod);
        }

        public static void xml(String message)
        {
            Append(message, LogLevel.XML, false);
        }

        public static void xml(bool previousMethod, String message)
        {
            Append(message, LogLevel.XML, previousMethod);
        }

        public static void sql(int connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.SQL, false);
        }

        public static void sql(bool previousMethod, int connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.SQL, previousMethod);
        }

        public static void database(String message)
        {
            Append(message, LogLevel.DATABASE, false);
        }

        public static void database(int connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.DATABASE, false);
        }

        public static void database(bool previousMethod, String message)
        {
            Append(message, LogLevel.DATABASE, previousMethod);
        }

        public static void database(bool previousMethod, int connectionNum, String message)
        {
            Append("<" + connectionNum.ToString() + "> " + message, LogLevel.DATABASE, previousMethod);
        }

        public static void gui(String message)
        {
            Append(message, LogLevel.GUI, false);
        }

        public static void gui(bool previousMethod, String message)
        {
            Append(message, LogLevel.GUI, previousMethod);
        }

        public static void transakcja(String message)
        {
            Append(message, LogLevel.TRANSAKCJA, false);
        }

        public static void transakcja(bool previousMethod, String message)
        {
            Append(message, LogLevel.TRANSAKCJA, previousMethod);
        }

        public static void debug(String message)
        {
            Append(message, LogLevel.DEBUG, false);
        }

        public static void debug(bool previousMethod, String message)
        {
            Append(message, LogLevel.DEBUG, previousMethod);
        }

        public static void info(String message)
        {
            Append(message, LogLevel.INFO, false);
        }

        public static void warn(String message)
        {
            Append(message, LogLevel.WARN, false);
        }

        public static void error(bool previousMethod, String message)
        {
            Append(message, LogLevel.ERROR, previousMethod);
        }

        public static void error(String message)
        {
            Append(message, LogLevel.ERROR, false);
        }

        public static void fatal(String message)
        {
            Append(message, LogLevel.FATAL, false);
        }

        public static void exception(Exception e)
        {
            Append(e.ToString(), LogLevel.ERROR, false);
        }

        public static void stacktrace()
        {
            debug(Environment.StackTrace.ToString());
        }

        public static ushort getLogLogLevel()
        {
            return logLevel;
        }

        public static void setLogLogLevel(ushort logLevel)
        {
            info("log set to " + logLevel);
            logger.logLevel = logLevel;
        }

        public static void setLogLogLevelFromSettings(ushort logLevel)
        {
            info("log settings set to " + logLevel);
            logger.logLevel = logLevel;
        }

        /*public static String getPrevMethodName()
        {
            string[] stackTrace = Environment.StackTrace.Split(Environment.NewLine.ToCharArray());
            return stackTrace[8].Substring(7 + 6); // 6 = "SmartR";
        }*/

        public static String GetNameByLogLevel(logger.LogLevel level)
        {
            switch (level)
            {
                case LogLevel.RES:
                    return "RES";
                case LogLevel.AUDIO:
                    return "AUDIO";
                case LogLevel.XMPLAYER:
                    return "XMPLR";
                case LogLevel.TODO:
                    return "TODO";
                case LogLevel.SQL:
                    return "SQL";
                case LogLevel.DATABASE:
                    return "DB";
                case LogLevel.TRANSAKCJA:
                    return "TRANS";
                case LogLevel.GUI:
                    return "GUI";
                case LogLevel.XML:
                    return "XML";
                case LogLevel.DEBUG:
                    return "DEBUG";
                case LogLevel.CONNECTION:
                    return "CON";
                case LogLevel.INFO:
                    return "INFO";
                case LogLevel.WARN:
                    return "WARN";
                case LogLevel.ERROR:
                    return "ERROR";
                case LogLevel.FATAL:
                    return "FATAL";
                default:
                    return "UNKNOWN";
            }
        }

        public static void Append(String message, LogLevel level, bool previousMethod)
        {
            if (useLogger == false || logger.logLevel == (ushort)LogLevel.ALL_OFF)
                return;

            if (logger.IsLogLevelSet(level))
            {
                string methodName = "";
                string threadName = "";

#if !FULL_DEMO
                if (logMethodName)
                {
                    try
                    {
                        StackTrace callStack = new StackTrace();
                        StackFrame stackFrame = (previousMethod ? callStack.GetFrame(3) : callStack.GetFrame(2));
                        MethodBase methodBase = stackFrame.GetMethod();
                        // 7="SmartR."
                        methodName = methodBase.DeclaringType.FullName.Substring(7) + "." + methodBase.Name;

                        if (methodName.Length > PAD_METHOD_LENGTH)
                        {
                            methodName = methodName.Substring(methodName.Length - PAD_METHOD_LENGTH);
                        }
                        else
                        {
                            methodName = methodName.PadRight(PAD_METHOD_LENGTH, ' ');
                        }
                    }
                    catch
                    {
                        logMethodName = false;
                        methodName = "";
                    }
                }

                if (logThreadName)
                {
                    threadName = System.Threading.Thread.CurrentThread.Name;
                    if (threadName == null)
                        threadName = System.Threading.Thread.CurrentThread.ManagedThreadId.ToString();
                }
#endif

                try
                {
                    lock (logger.logAppenders)
                    {
                        foreach (ILogAppender logAppender in logger.logAppenders)
                        {
                            logAppender.LogEvent(level, DateTime.Now, methodName, threadName, message);
                        }
                    }
                }
                catch
                {
                    // do nothing
                }
            }

        }
    }
}
