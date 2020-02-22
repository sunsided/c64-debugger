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
using System.Runtime.Serialization.Formatters.Binary;

namespace LogConsole.LogEngine
{
    public class LogEventsBuffer
    {
        public const byte BYTE_TRUE = (byte)0x01;
        public const byte BYTE_FALSE = (byte)0x00;

        public static System.Text.ASCIIEncoding asciiEncoder = new System.Text.ASCIIEncoding();
        public static System.Text.UTF8Encoding utf8Encoder = new System.Text.UTF8Encoding();

        byte[] tmp = new byte[4];
        public byte[] data;
        public int index;
        public int dataLength;

        public bool byteLog = false;
        private byte[] tmpSizeBytes = new byte[4];

        public LogEventsBuffer(int size)
        {
            data = new byte[size];
            index = 0;
            dataLength = 0;
        }

        public void Clear()
        {
            index = 0;
            dataLength = 0;
        }

        public LogEventsBuffer(byte[] buffer)
        {
            if (buffer == null)
                throw new ByteBufferException("buffer null");

            this.data = buffer;
            this.dataLength = buffer.Length;
            index = 0;
        }

        public LogEventsBuffer(byte[] buffer, int size)
        {
            if (buffer == null)
                throw new ByteBufferException("buffer null");

            this.data = new byte[size];
            Array.Copy(buffer, 0, this.data, 0, size);
            this.dataLength = size;
            index = 0;
        }

        public LogEventsBuffer()
            : this(1024)
        {
        }

        public override String ToString()
        {
            return LogEventsBuffer.BytesToHexString(data, index, " ");
        }

        public bool IsEof()
        {
            return (index == this.dataLength);
        }

        private bool isBufferEof()
        {
            //logger.debug("isEof, index=" + index + " length=" + data.length);
            return (index == data.Length);
        }

        public void Seek(int numBytes)
        {
            if (index + numBytes < 0)
                throw new ByteBufferException("Seek failed: index=" + index + " numBytes=" + numBytes);
            if (index + numBytes > dataLength)
                throw new ByteBufferException("Seek failed: index=" + index + " numBytes=" + numBytes);

            index += numBytes;
        }

        public void PutByte(byte b)
        {
            if (isBufferEof())
            {
                byte[] newData = new byte[data.Length * 2];
                Array.Copy(data, 0, newData, 0, data.Length);
                data = newData;
            }
            data[index++] = b;
            dataLength++;
        }

        public void PutByte(int b)
        {
            PutByte((byte)(b & 0x00FF));
        }

        public byte GetByte()
        {
            if (index == dataLength)
            {
                throw new ByteBufferException("end of stream reached");
            }

            return data[index++];
        }

        public void PutBytes(byte[] b)
        {
            PutBytes(b, 0, b.Length);
        }

        public void PutBytes(byte[] b, int length)
        {
            for (int i = 0; i < length; i++)
            {
                PutByte(b[i]);
            }
        }

        public void PutBytes(byte[] b, int begin, int length)
        {
            for (int i = 0; i < length; i++)
            {
                PutByte(b[begin + i]);
            }
        }

        public byte[] GetBytes(int len)
        {
            byte[] b = new byte[len];

            for (int i = 0; i < len; i++)
            {
                b[i] = GetByte();
            }

            return b;
        }

        public void PutBytesArray(byte[] b)
        {
            PutInt(b.Length);
            PutBytes(b);
        }

        public byte[] GetBytesArray()
        {
            int len = GetInt();
            return GetBytes(len);
        }

        public void PutByteBuffer(LogEventsBuffer byteBuffer)
        {
            //logger.debug("putByteBuffer: " + byteBuffer.toString());
            PutInt(byteBuffer.dataLength);
            PutBytes(byteBuffer.data, byteBuffer.dataLength);
        }

        public LogEventsBuffer GetByteBuffer()
        {
            int size = GetInt();
            byte[] bytes = GetBytes(size);

            return new LogEventsBuffer(bytes, size);
        }

        public void PutString(byte[] b)
        {
            this.PutString(b, 0, b.Length);
        }

        public void PutString(byte[] b, int begin, int length)
        {
            PutInt(length);
            PutBytes(b, begin, length);
        }

        public void PutASCIIString(String str)
        {
            PutString(asciiEncoder.GetBytes(str));
        }

        public String GetASCIIString()
        {
            int len = GetInt();
            byte[] strBytes = new byte[len];

            strBytes = GetBytes(len);
            return asciiEncoder.GetString(strBytes);
        }

        public void PutString(String str)
        {
            PutString(utf8Encoder.GetBytes(str));
        }

        public String GetString()
        {
            int len = GetInt();
            byte[] strBytes = new byte[len];

            strBytes = GetBytes(len);

            return utf8Encoder.GetString(strBytes);
        }

        public void PutDecimal(Decimal value)
        {
            // is this optimal?
            using (MemoryStream stream = new MemoryStream())
            {
                using (BinaryWriter writer = new BinaryWriter(stream))
                {
                    writer.Write(value);
                    this.PutBytesArray(stream.ToArray());
                }
            }
        }

        public Decimal GetDecimal()
        {
            byte[] src = this.GetBytesArray();

            if (src.Length == 1)
            {
                return Decimal.Parse(((char)src[0]).ToString());
            }

            using (MemoryStream stream = new MemoryStream(src))
            {
                using (BinaryReader reader = new BinaryReader(stream))
                {
                    return reader.ReadDecimal();
                }
            }
        }


        /*
        public void PutStringVector(Vector strVect)
        {
            putInt(strVect.size());
            for (int i = 0; i < strVect.size(); i++)
            {
                putString((String)strVect.get(i));
            }
        }

        public Vector getStringVector() throws EBadBufferData
        {
            Vector strVect = new Vector();

            int size = getInt();
            for (int i = 0; i < size; i++)
            {
                strVect.add(getString());
            }
            return strVect;
        }

        public void putIntVector(Vector intVect)
        {
            putInt(intVect.size());
            for (int i = 0; i < intVect.size(); i++)
            {
                putInt((Integer)intVect.get(i));
            }
        }

        public Vector getIntVector() throws EBadBufferData
        {
            Vector intVect = new Vector();

            int size = getInt();
            for (int i = 0; i < size; i++)
            {
                intVect.add(new Integer(getInt()));
            }
            return intVect;
        }

        public void putIntArray(int[] intArray)
        {
            putInt(intArray.length);
            for (int i = 0; i < intArray.length; i++)
            {
                putInt(intArray[i]);
            }
        }
        */

        public int[] GetIntArray()
        {
            int size = GetInt();
            int[] intArray = new int[size];
            for (int i = 0; i < size; i++)
            {
                intArray[i] = GetInt();
            }
            return intArray;
        }

        public void PutShort(int val)
        {
            PutByte((byte)(val >> 8));
            PutByte((byte)(val));
        }

        public int GetShort()
        {
            int s = GetByte();
            s = ((s << 8) & 0xFF00) | (GetByte() & 0xFF);
            return s;
        }

        public void PutInt(int val)
        {
            PutByte((byte)(val >> 24));
            PutByte((byte)(val >> 16));
            PutByte((byte)(val >> 8));
            PutByte((byte)(val));
        }

        public int GetInt()
        {
            int i = GetShort();
            i = (int)((i << 16) & 0xFFFF0000) | (GetShort() & 0xFFFF);
            return i;
        }

        public void SeekInt(int num)
        {
            this.Seek(num * 4);
        }

        public void SeekWriteInt(int num)
        {
            this.Seek(num * 4);
            dataLength -= num * 4;
        }

        public void PutLong(long val)
        {
            PutByte((byte)(val >> 56));
            PutByte((byte)(val >> 48));
            PutByte((byte)(val >> 40));
            PutByte((byte)(val >> 32));
            PutByte((byte)(val >> 24));
            PutByte((byte)(val >> 16));
            PutByte((byte)(val >> 8));
            PutByte((byte)(val));
        }

        public long GetLong()
        {
            long l = this.GetInt() & 0xFFFFFFFFL;
            l = ((l << 32)) | (this.GetInt() & 0xFFFFFFFFL);
            return l;
        }

        public void PutBoolean(bool val)
        {
            if (val)
                PutByte(BYTE_TRUE);
            else
                PutByte(BYTE_FALSE);
        }

        public bool GetBoolean()
        {
            if (this.GetByte() == BYTE_TRUE)
                return true;
            else return false;
        }

        public void PutDate(DateTime date)
        {
            PutInt(date.Year);
            PutByte(date.Month);
            PutByte(date.Day);
        }

        public DateTime GetDate()
        {
            DateTime date = new DateTime(GetInt(), GetByte(), GetByte());
            return date;
        }

        public void PutDateTime(DateTime dateTime)
        {
            PutInt(dateTime.Year);
            PutByte(dateTime.Month);
            PutByte(dateTime.Day);
            PutByte(dateTime.Hour);
            PutByte(dateTime.Minute);
            PutByte(dateTime.Second);
            PutInt(dateTime.Millisecond);
        }

        public DateTime GetDateTime()
        {
            int year = GetInt();
            byte month = GetByte();
            byte day = GetByte();
            byte hour = GetByte();
            byte minute = GetByte();
            byte second = GetByte();
            int millisecond = GetInt();

            DateTime dateTime = new DateTime(year, month, day, hour, minute, second, millisecond);
            return dateTime;
        }

        public void PutSerializedObject(object objectToSerialize)
        {
            MemoryStream memoryStream = new MemoryStream();
            BinaryFormatter binaryFormatter = new BinaryFormatter();
            binaryFormatter.Serialize(memoryStream, objectToSerialize);
            this.PutBytesArray(memoryStream.ToArray());
        }

        public Object GetSerializedObject()
        {
            byte[] serializedData = this.GetBytesArray();

            MemoryStream memoryStream = new MemoryStream(serializedData);
            BinaryFormatter binaryFormatter = new BinaryFormatter();
            memoryStream.Position = 0;

            return binaryFormatter.Deserialize(memoryStream);
        }

        public void PutMemoryStream(MemoryStream memoryStream)
        {
            this.PutBytesArray(memoryStream.ToArray());
        }

        public MemoryStream GetMemoryStream()
        {
            byte[] serializedData = this.GetBytesArray();

            MemoryStream memoryStream = new MemoryStream(serializedData);
            memoryStream.Position = 0;

            return memoryStream;
        }

        public void PutObjectsList(List<Object> objectsList)
        {
            this.PutInt(objectsList.Count);
            foreach (Object obj in objectsList)
            {
                this.PutSerializedObject(obj);
            }
        }

        public void GetObjectsList(List<Object> objectsList)
        {
            objectsList.Clear();
            int count = this.GetInt();
            for (int i = 0; i < count; i++)
            {
                objectsList.Add(this.GetSerializedObject());
            }
        }

        public static byte[] SerializeObjectToByteArray(object objectToSerialize)
        {
            MemoryStream memoryStream = new MemoryStream();
            BinaryFormatter binaryFormatter = new BinaryFormatter();
            binaryFormatter.Serialize(memoryStream, objectToSerialize);
            return memoryStream.ToArray();
        }

        public static Object DeserializeObjectFromByteArray(byte[] serializedData)
        {
            MemoryStream memoryStream = new MemoryStream(serializedData);
            BinaryFormatter binaryFormatter = new BinaryFormatter();
            memoryStream.Position = 0;

            return binaryFormatter.Deserialize(memoryStream);
        }

        public void Scramble()
        {
            for (int i = 0; i < this.dataLength; i++)
            {
                this.data[i] ^= (byte)((i * 66.6) % 0xFF);
            }
        }

        public void Descramble()
        {
            Scramble();
        }

        public void WriteToFile(FileStream fs)
        {
            BinaryWriter bw = new BinaryWriter(fs);
            tmpSizeBytes[0] = (byte)((this.index) >> 24);
            tmpSizeBytes[1] = (byte)((this.index) >> 16);
            tmpSizeBytes[2] = (byte)((this.index) >> 8);
            tmpSizeBytes[3] = (byte)(this.index);
            bw.Write(tmpSizeBytes, 0, 4);

            this.Scramble();
            bw.Write(this.data, 0, this.dataLength);
        }

        public void ReadFromFile(FileStream fs)
        {
            BinaryReader br = new BinaryReader(fs);
            br.Read(tmpSizeBytes, 0, 4);

            this.dataLength = tmpSizeBytes[3] | (tmpSizeBytes[2] << 8) | (tmpSizeBytes[1] << 16) | (tmpSizeBytes[0] << 24);
            this.index = 0;
            this.data = new byte[this.dataLength];

            br.Read(this.data, 0, this.dataLength);
            this.Descramble();
        }

        public static String BytesToHexString(byte[] inBuf, int size, String separator)
        {
            byte ch = 0x00;

            String[] hexTable = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" };
            String outBuf = "";

            int i = 0;

            while (i < size)
            {
                ch = (byte)(inBuf[i] & 0xF0);
                ch = (byte)(ch >> 4);
                ch = (byte)(ch & 0x0F);

                outBuf += hexTable[(int)ch];
                ch = (byte)(inBuf[i] & 0x0F);
                outBuf += hexTable[(int)ch];

                outBuf += separator;
                i++;
            }

            return outBuf;
        }

        public static String BytesToHexString(byte[] inBuf)
        {
            return BytesToHexString(inBuf, inBuf.Length, " ");
        }

        public class ByteBufferException : ApplicationException
        {
            public ByteBufferException()
            {
            }

            public ByteBufferException(string message)
                : base(message)
            {
            }
            public ByteBufferException(string message, Exception inner)
                : base(message, inner)
            {
            }
        }

    }
}
