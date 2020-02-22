package com.ir.hough;

import com.ir.Main;

import java.awt.*;

public class HoughLine
{
	int[] input;
	int[] output;

	double progress;
	int width;
	int height;
	int[] acc;
	int accSize = 30;
	int[] results;

	public void HoughLine()
	{
		progress = 0;
	}

	public void init(int[] inputIn, int widthIn, int heightIn)
	{
		width = widthIn;
		height = heightIn;
		input = new int[width * height];
		output = new int[width * height * 4];
		input = inputIn;
		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				output[x * width + y] = 0xff000000;
			}
		}
	}

	public void setLines(int lines)
	{
		accSize = lines;
		startPt = new Point[accSize];
		endPt = new Point[accSize];
		linesStart = 0;
		linesEnd = 0;
	}

	// transformacja hough'a dla linii. zwraca zakumulowaną tablicę pixeli
	public int[] process()
	{
		int rmax = (int)Math.sqrt(width * width + height * height);
		// 180 stopni * najdłuższa możliwa linia w obrazie (przękątna obrazu)
		acc = new int[rmax * 180];
		int r;
		progress = 0;

		for (int x = 0; x < width; x++)
		{
			progress += 0.5;
			for (int y = 0; y < height; y++)
			{
				// na wejściu czarny pixel
				if ((input[y * width + x] & 0xff) == 255)
				{
					// sprawdzamy okoliczne dla kąta 180 stopni
					for (int theta = 0; theta < 180; theta++)
					{
						r = (int)(x * Math.cos(((theta) * Math.PI) / 180) + y * Math.sin(((theta) * Math.PI) / 180));
						if ((r > 0) && (r <= rmax)) // jeśli promień większy niż 0 i nie większy niż maksymalny, wpisz do tablicy akumulującej
							acc[r * 180 + theta] = acc[r * 180 + theta] + 1;
					}
				}
			}
		}
		// a teraz normalizujemy do 255 oraz uzupełniamy tablicę. wpierw wyszukanie maksimum
		int max = 0;

		for (r = 0; r < rmax; r++)
		{
			for (int theta = 0; theta < 180; theta++)
			{
				if (acc[r * 180 + theta] > max)
				{
					max = acc[r * 180 + theta];
				}
			}
		}

		// i normalizacja
		int value;
		for (r = 0; r < rmax; r++)
		{
			for (int theta = 0; theta < 180; theta++)
			{
				value = (int)(((double)acc[r * 180 + theta] / (double)max) * 255.0);
				acc[r * 180 + theta] = 0xff000000 | (value << 16 | value << 8 | value);
			}
		}
		findMaxima();

		if (Main.DEBUG)
			Main._log.info("hough: zakończono");
		return output;
	}

	private int[] findMaxima()
	{
		int rmax = (int)Math.sqrt(width * width + height * height);
		results = new int[accSize * 3];
		for (int r = 0; r < rmax; r++)
		{
			for (int theta = 0; theta < 180; theta++)
			{
				int value = (acc[r * 180 + theta] & 0xff);

				// jeśli wartość większa niż najniższa, dodaj a następnie posortuj
				if (value > results[(accSize - 1) * 3])
				{
					// dodaj na końcu
					results[(accSize - 1) * 3] = value;
					results[(accSize - 1) * 3 + 1] = r;
					results[(accSize - 1) * 3 + 2] = theta;

					// przesuń w górę, do momentu, gdy we właściwej pozycji
					int i = (accSize - 2) * 3;
					while ((i >= 0) && (results[i + 3] > results[i]))
					{
						for (int j = 0; j < 3; j++)
						{
							int temp = results[i + j];
							results[i + j] = results[i + 3 + j];
							results[i + 3 + j] = temp;
						}
						i = i - 3;
						if (i < 0) break;
					}
				}
			}
		}

		double ratio = (double)(width / 2) / accSize;
		if (Main.DEBUG)
			Main._log.info("najlepsze " + accSize + " trafienia:");
		for (int i = accSize - 1; i >= 0; i--)
		{
			progress += ratio;
			// oblicz punkty początku i końca linii
			drawPolarLine(results[i * 3], results[i * 3 + 1], results[i * 3 + 2]);
		}
		return output;
	}

	int linesStart = 0;
	int linesEnd = 0;

	private void drawPolarLine(int value, int r, int theta)
	{
		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				int temp = (int)(x * Math.cos(((theta) * Math.PI) / 180) + y * Math.sin(((theta) * Math.PI) / 180));
				if ((temp - r) == 0)
				{
					// obliczenie punktu początku i końca linii
					output[y * width + x] = 0xff000000 | (value << 16 | value << 8 | value);
					if (x == 0 && linesStart < accSize)
					{
						startPt[linesStart] = new Point(x, y);
						linesStart++;
					}
					else if (x == width - 1 && linesEnd < accSize)
					{
						endPt[linesEnd] = new Point(x, y);
						linesEnd++;
					}
				}
			}
		}
	}

	private Point[] startPt;
	private Point[] endPt;

	public Point[] getLineCoords(boolean isUpper)
	{
		Point start = new Point();
		Point end = new Point();
		if (isUpper)
		{
			end.y = 0;
			start.y = 0;
		}
		else
		{
			end.y = height;
			start.y = height;
		}
		for (Point point : startPt)
		{
			if (point == null)
				continue;
			if (isUpper)
			{
				// wyszukaj najwyższy punkt startowy
				if (point.y > start.y)
				{
					start.y = point.y;
					start.x = point.x;
				}
			}
			else
			{
				// wyszukaj najniższy punkt startowy
				if (point.y < start.y)
				{
					start.y = point.y;
					start.x = point.x;
				}
			}
		}

		for (Point point : endPt)
		{
			if (point != null)
			{
				if (isUpper)
				{
					// wyszukaj najwyższy punkt końcowy
					if (point.y > end.y)
					{
						end.y = point.y;
						end.x = point.x;
					}
				}
				else
				{
					// wyszukaj najniższy punkt końcowy
					if (point.y < end.y)
					{
						end.y = point.y;
						end.x = point.x;
					}
				}
			}
		}
		Point[] out = new Point[2];
		out[0] = start;
		out[1] = end;
		return out;
	}

	public int[] getAcc()
	{
		return acc;
	}

	public int getProgress()
	{
		return (int)progress;
	}
}
