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
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using LogConsole.LogEngine;
using LogConsole.Appenders;
using System.Threading;
using System.Diagnostics;

namespace LogConsole.LogEngine
{
    static class LogConsoleProgram
    {
        public static FastConsoleAppender logConsoleWindow;
        public static int hostProcID = -1;
        public static String settingsName;
        public static String windowCaption;

        private static Random random = new Random();

        // debug
        //private static FastConsoleProcessAppender appender = null;

        /// <summary>
        /// Runs the FastLogConsole process
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            if (args.Length != 3)
            {
                Environment.Exit(-1);
            }

            try
            {
                hostProcID = Convert.ToInt32(args[0]);
                settingsName = args[1];
                windowCaption = args[2];
            }
            catch
            {
                Environment.Exit(-1);
            }

            //Random rand = new Random();
            //int hostProcID = 9999; // rand.Next(100000);

            //logger.Startup("LogConsole_");
            //logger.debug("hostProcID=" + hostProcID);

            logger.RegisterWindowCloseCallback(new WindowCloseCallback());

            //appender = new FastConsoleProcessAppender(hostProcID);
            Engine.Startup(hostProcID);

            while (Engine.IsReady == false)
            {
                Thread.Sleep(15);
            }

            Settings.Startup(settingsName);
            logConsoleWindow = new FastConsoleAppender(windowCaption);
            logConsoleWindow.Show();

            //DoTest();

            Application.Run();
        }

        public static void Shutdown()
        {
            //logger.debug("shutdown");
            Process.GetCurrentProcess().Kill();
        }

        public class WindowCloseCallback : ILogWindowClose
        {
            public void LogWindowClose()
            {
                if (LogConsoleProgram.hostProcID != -1)
                {
                    try
                    {
                        Process hostProc = Process.GetProcessById(hostProcID);
                        if (hostProc != null)
                            hostProc.Kill();
                    }
                    catch
                    {
                    }
                }
            }
        }

        /*
        public static void DoTest()
        {
            Thread perform = new Thread(delegate()
            {
                //Thread.Sleep(1000);
                Stopwatch stopWatch = new Stopwatch();
                stopWatch.Start();
                for (int j = 0; j < 10000; j++)
                {
                    //String line = "ABCDEFGHJIJKLMNOPQRSTUWXXYZ1234567890ABCDEFGHJIJKLMNOPQRSTUWXXYZ1234567890";

                    //line += line + line;
                    appender.LogEvent(Logger.LogLevel.DEBUG, DateTime.Now, "method", "thread", 
                    //Logger.debug(
                    "j=" + j
                        + " time=" + stopWatch.ElapsedMilliseconds
                        + " rand=" + GetRandom(0, 100000));   //" " + line); //
                    //Thread.Sleep(10);
                }

                Logger.debug("perform time=" + stopWatch.ElapsedMilliseconds);
            });
            perform.Priority = ThreadPriority.Lowest;
            perform.Start();
        }

        public static int GetRandom(int min, int max)
        {
            return random.Next(min, max);
        }
         */
    }
}
