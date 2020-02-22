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
using System.Text;
using System.IO;

namespace LogConsole.Appenders
{
    public class FileAppender : ILogAppender
    {
        private const String logDir = ".\\log\\";
        private static StreamWriter sw;
        private static String logFile;

        public FileAppender(String fileName)
        {
            if (!Directory.Exists(logDir))
            {
                Directory.CreateDirectory(logDir);
            }

            logFile = logDir + fileName + DateTime.Now.ToString("yyMMdd_HHmmss") + ".txt";

            // if the file doesn't exist, create it
            if (!File.Exists(logFile))
            {
                FileStream fs = File.Create(logFile);

                // write the utf8 marker
                byte[] bytes = new byte[3];
                bytes[0] = 0xEF;
                bytes[1] = 0xBB;
                bytes[2] = 0xBF;
                BinaryWriter writer = new BinaryWriter(fs);
                writer.Write(bytes, 0, 3);

                fs.Close();
            }

            sw = File.AppendText(logFile);

        }

        public void Shutdown()
        {
            lock (sw)
            {
                //logger.info("Logger destroyed");
                sw.Close();
                sw.Dispose();
                sw = null;
            }
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            if (sw == null)
                return;

            String strLevel = "[" + logger.GetNameByLogLevel(logLevel) + "]";
            String line = time.ToString("yyyy-MM-dd HH:mm:ss,fff")
                + (threadName != null ? " " + threadName.PadRight(6, ' ') : "")
                + (methodName != null ? methodName : "")
                + " " + strLevel.PadRight(7)
                + " " + message;

            lock (sw)
            {
                sw.WriteLine(line);
                sw.Flush();
            }
        }
    }


}
