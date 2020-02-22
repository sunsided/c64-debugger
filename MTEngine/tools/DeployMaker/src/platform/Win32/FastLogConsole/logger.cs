/*
 **************************************************************************
 *
 *    Copyright 2008 Marcin Skoczylas    
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 **************************************************************************
 * 
 * @author: Marcin.Skoczylas@pb.edu.pl
 *  
 */

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
using LogConsole.LogEngine;

namespace LogConsole
{
    public class logger
    {
        public static String datePattern = "yyyy-MM-dd HH:mm:ss,fff";
        public static String dateFilePattern = "yyMMdd_HHmmss";

        private const int PAD_METHOD_LENGTH = 47;
        public static volatile bool useLogger = true;

        public static ushort defaultLogLevel =
           (ushort)LogLevel.FATAL | (ushort)LogLevel.ERROR
           | (ushort)LogLevel.WARN | (ushort)LogLevel.INFO
           | (ushort)LogLevel.DEBUG | (ushort)LogLevel.CONNECTION
           | (ushort)LogLevel.GUI; // | (ushort)LogLevel.XML;
           //| (ushort)LogLevel.TRANSAKCJA;

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
            TRANSACTION = (1 << 5),
            CONNECTION  = (1 << 6),
            DEBUG       = (1 << 7),
            DATABASE    = (1 << 8),
            SQL         = (1 << 9),
            XML         = (1 << 10),
            RES	        = (1 << 11),
            PLAYER	    = (1 << 12),
            AUDIO	    = (1 << 13),
            TODO		= (1 << 14),
            MEMORY      = (1 << 15)
        }

        public static String GetNameByLogLevel(logger.LogLevel level)
        {
            switch (level)
            {
                case LogLevel.RES:
                    return "RES";
                case LogLevel.AUDIO:
                    return "AUDIO";
                case LogLevel.PLAYER:
                    return "PLAY";
                case LogLevel.TODO:
                    return "TODO";
                case LogLevel.SQL:
                    return "SQL";
                case LogLevel.DATABASE:
                    return "DB";
                case LogLevel.TRANSACTION:
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
                case LogLevel.MEMORY:
                    return "MEM";
                default:
                    return "UNKNOWN";
            }
        }

        public static UInt32 GetColorByLogLevel(logger.LogLevel level)
        {
            switch (level)
            {
                case logger.LogLevel.FATAL:
                    return NativeMethods.GetRGB(0xFF, 0x00, 0xFF);
                case logger.LogLevel.ERROR:
                    return NativeMethods.GetRGB(0xFF, 0x00, 0x00);
                case logger.LogLevel.WARN:
                    return NativeMethods.GetRGB(0x80, 0x00, 0x80);
                case logger.LogLevel.GUI:
                    return NativeMethods.GetRGB(0x00, 0xFF, 0xFF);
                case logger.LogLevel.XML:
                    return NativeMethods.GetRGB(0x40, 0x80, 0xF0);
                case logger.LogLevel.INFO:
                    return NativeMethods.GetRGB(0xFF, 0xFF, 0x00);
                case logger.LogLevel.TRANSACTION:
                    return NativeMethods.GetRGB(0x00, 0xFF, 0x00);
                case logger.LogLevel.CONNECTION:
                    return NativeMethods.GetRGB(0x60, 0x30, 0xFF);
                case logger.LogLevel.DEBUG:
                    return NativeMethods.GetRGB(0xFF, 0xFF, 0xFF);
                case logger.LogLevel.DATABASE:
                    return NativeMethods.GetRGB(0x00, 0x80, 0x80);
                case logger.LogLevel.SQL:
                    return NativeMethods.GetRGB(0x00, 0xFF, 0xFF);
                case logger.LogLevel.RES:
                    return NativeMethods.GetRGB(0x00, 0x80, 0x80);
                case logger.LogLevel.AUDIO:
                    return NativeMethods.GetRGB(0x40, 0xF0, 0x40);
                case logger.LogLevel.PLAYER:
                    return NativeMethods.GetRGB(0x10, 0xF0, 0x10);
                case logger.LogLevel.TODO:
                    return NativeMethods.GetRGB(0xFF, 0x40, 0x40);
                case logger.LogLevel.MEMORY:
                    return NativeMethods.GetRGB(0xFF, 0x60, 0x60);

                default:
                    return NativeMethods.GetRGB(0xFF, 0xFF, 0xFF);
            }
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

        // for testing purposes only!
        public static void ClearAppenders()
        {
            lock (logger.logAppenders)
            {
                /*
                foreach (ILogAppender appender in logger.logAppenders)
                {
                    appender.Shutdown();
                }*/
                logger.logAppenders.Clear();
            }
        }

        public static void RegisterAppender(ILogAppender appender)
        {
            lock (logger.logAppenders)
            {
                logger.logAppenders.Add(appender);
            }
        }

        public static void RemoveAppender(ILogAppender appender)
        {
            lock (logger.logAppenders)
            {
                logger.logAppenders.Remove(appender);
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

        public static void gui(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.GUI, false);
        }

        public static void gui(bool previousMethod, String message)
        {
            Append(message, LogLevel.GUI, previousMethod);
        }

        public static void gui(bool previousMethod, String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.GUI, previousMethod);
        }

        public static void transaction(String message)
        {
            Append(message, LogLevel.TRANSACTION, false);
        }

        public static void transaction(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.TRANSACTION, false);
        }

        public static void transakcja(bool previousMethod, String message)
        {
            Append(message, LogLevel.TRANSACTION, previousMethod);
        }

        public static void transaction(bool previousMethod, String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.TRANSACTION, previousMethod);
        }

        public static void debug(String message)
        {
            Append(message, LogLevel.DEBUG, false);
        }

        public static void debug(bool previousMethod, String message)
        {
            Append(message, LogLevel.DEBUG, previousMethod);
        }

        public static void debug(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.DEBUG, false);
        }

        public static void debug(bool previousMethod, String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.DEBUG, previousMethod);
        }

        public static void info(String message)
        {
            Append(message, LogLevel.INFO, false);
        }

        public static void info(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.INFO, false);
        }

        public static void warn(String message)
        {
            Append(message, LogLevel.WARN, false);
        }

        public static void warn(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.WARN, false);
        }

        public static void error(bool previousMethod, String message)
        {
            Append(message, LogLevel.ERROR, previousMethod);
        }

        public static void error(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.ERROR, false);
        }

        public static void error(bool previousMethod, String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.ERROR, previousMethod);
        }

        public static void error(String message)
        {
            Append(message, LogLevel.ERROR, false);
        }

        public static void fatal(String message)
        {
            Append(message, LogLevel.FATAL, false);
        }

        public static void fatal(String format, params object[] args)
        {
            Append(String.Format(format, args), LogLevel.FATAL, false);
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

        public static void Append(String message, LogLevel level, bool previousMethod)
        {
            if (useLogger == false || logger.logLevel == (ushort)LogLevel.ALL_OFF)
                return;

            if (logger.IsLogLevelSet(level))
            {
                string methodName = "";
                string threadName = "";

                if (logMethodName)
                {
                    try
                    {
                        StackTrace callStack = new StackTrace();
                        StackFrame stackFrame = (previousMethod ? callStack.GetFrame(3) : callStack.GetFrame(2));
                        MethodBase methodBase = stackFrame.GetMethod();
                        // 9="namespace."
                        //methodName = methodBase.DeclaringType.FullName.Substring(9) + "." + methodBase.Name;
                        methodName = methodBase.DeclaringType.FullName + "." + methodBase.Name;

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
