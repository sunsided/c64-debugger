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
    public class HTMLFileAppender : ILogAppender
    {
        private const int HTML_PAD_METHOD_LENGTH = 30;

        private const String logDir = ".\\log\\";
        private static StreamWriter sw;
        private static String logFile;

        public HTMLFileAppender(String fileName)
        {
            if (!Directory.Exists(logDir))
            {
                Directory.CreateDirectory(logDir);
            }

            logFile = logDir + fileName + DateTime.Now.ToString(logger.dateFilePattern) + ".html";

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
                writer.Close();
                fs.Close();
                
                StreamWriter writerUtf = File.AppendText(logFile);
                writerUtf.WriteLine("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"); 
                writerUtf.WriteLine("<html xmlns=\"http://www.w3.org/1999/xhtml\"><head>");
                writerUtf.WriteLine("<title>" + DateTime.Now.ToString("yyMMdd_HHmmss") + "</title>");
                writerUtf.WriteLine("<body BGCOLOR=\"#000000\" TEXT=\"#FFFFFF\">");
                writerUtf.WriteLine("<font face=\"courier\">");
                writerUtf.Close();
 
            }

            sw = File.AppendText(logFile);

        }

        public void Shutdown()
        {
            lock (sw)
            {
                //logger.info("Logger destroyed");
                sw.WriteLine("</font></body></html>");
                sw.Close();
                sw.Dispose();
                sw = null;
            }
        }

        static char[] hexDigits = {
         '0', '1', '2', '3', '4', '5', '6', '7',
         '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

        byte[] bytes = new byte[3];
        char[] chars = new char[3 * 2];

        public String ConvertToHTML(String text)
        {
            StringBuilder sb = new StringBuilder(text);
            sb.Replace(" ", "&nbsp;");
            sb.Replace("<", "&lt;");
            sb.Replace(">", "&gt;");
            sb.Replace("\"", "&quot;");
            return sb.ToString();
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            if (sw == null)
                return;

            String strLevel = "[" + logger.GetNameByLogLevel(logLevel) + "]";
            String line = time.ToString(logger.datePattern)
                + (threadName != null ? " " + threadName.PadRight(6, ' ') : "")
                + (methodName != null ? methodName : "")
                + " " + strLevel.PadRight(7)
                + " " + message;

            UInt32 color = logger.GetColorByLogLevel(logLevel);
            lock (sw)
            {
                bytes[0] = (byte)(color & 0x000000FF);
                bytes[1] = (byte)((color >> 8) & 0x000000FF);
                bytes[2] = (byte)((color >> 16) & 0x000000FF);
                for (int i = 0; i < bytes.Length; i++)
                {
                    int b = bytes[i];
                    chars[i * 2] = hexDigits[b >> 4];
                    chars[i * 2 + 1] = hexDigits[b & 0xF];
                }

                sw.Write("<font color=\"" + new string(chars) + "\">");
                sw.Write(ConvertToHTML(line));
                sw.WriteLine("</font><br>");
                sw.Flush();
            }
        }
    }
}
