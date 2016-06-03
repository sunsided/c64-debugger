package com.ir.hough;

import com.ir.Main;

import java.awt.*;
import java.util.Arrays;

public class HoughCircle
{
	int[] input;
	int[] output;

	double p;
	int width;
	int height;
	int[] acc;
	int accSize = 30;
	int[] results;
	public int r;
	public int value;

	public void HoughCircle()
	{
		p = 0;
	}

	public void init(int[] inputIn, int widthIn, int heightIn, int radius)
	{
		r = radius;
		width = widthIn;
		height = heightIn;
		input = new int[width * height];
		output = new int[width * height];
		input = inputIn;
		Arrays.fill(output, 0xff000000);
	}

	public void setLines(int lines)
	{
		accSize = lines;
	}

	/**
	 * transformacja hough'a. zwraca pixele w zbiorczej tablicy
	 * @return
	 */
	public int[] processBruteForce()
	{
		int rmax = (int)Math.sqrt(width * width + height * height);
		acc = new int[width * height * 2];
		int x0, y0;
		double t;
		p = 0;

		for (int x = 0; x < width; x++)
		{
			p += 0.5;
			for (int y = 0; y < height; y++)
			{
				if ((input[y * width + x] & 0xff) == 255)
				{
					for (int theta = 0; theta < 360; theta++)
					{
						t = (theta * 3.14159265) / 180;
						x0 = (int)Math.round(x - r * Math.cos(t));
						y0 = (int)Math.round(y - r * Math.sin(t));
						if (x0 < width && x0 > 0 && y0 < height && y0 > 0)
						{
							acc[x0 + (y0 * width)] += 1;
						}
					}
				}
			}
		}

		// normalizacja i zapis pixeli do zbiorczej tablicy
		int max = 0;

		// znalezienie maksymalnej wartości
		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				if (acc[x + (y * width)] > max)
				{
					max = acc[x + (y * width)];
				}
			}
		}
		value = max;
		//findMaxima();

		return output;
	}

	public int[] process()
	{
		int rmax = (int)Math.sqrt(width * width + height * height);
		acc = new int[width * height * 2];

		int x0, y0;
		double t;
		p = 0;

		for (int x = 0; x < width; x++)
		{
			p += 0.5;
			for (int y = 0; y < height; y++)
			{
				if ((input[y * width + x] & 0xff) == 255)
				{
					for (int theta = 0; theta < 360; theta++)
					{
						t = (theta * 3.14159265) / 180;
						x0 = (int)Math.round(x - r * Math.cos(t));
						y0 = (int)Math.round(y - r * Math.sin(t));
						if (x0 < width && x0 > 0 && y0 < height && y0 > 0)
						{
							acc[x0 + (y0 * width)] += 1;
						}
					}
				}
			}
		}

		// normalizacja i zapis pixeli do zbiorczej tablicy
		int max = 0;

		// znalezienie maksymalnej wartości
		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				if (acc[x + (y * width)] > max)
				{
					max = acc[x + (y * width)];
				}
			}
		}

		// normalizacja całości
		int _value;
		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				_value = (int)(((double)acc[x + (y * width)] / (double)max) * 255.0);
				acc[x + (y * width)] = 0xff000000 | (_value << 16 | _value << 8 | _value);
			}
		}
		findMaxima();

		return output;
	}

	private int[] findMaxima()
	{
		results = new int[accSize * 3];

		for (int x = 0; x < width; x++)
		{
			for (int y = 0; y < height; y++)
			{
				int _value = (acc[x + (y * width)] & 0xff);

				// jeśli wartość większa niż najniższa, dodaj a następnie posortuj
				if (_value > results[(accSize - 1) * 3])
				{
					// dodaj na końcu
					results[(accSize - 1) * 3] = _value;
					results[(accSize - 1) * 3 + 1] = x;
					results[(accSize - 1) * 3 + 2] = y;

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
		for (int i = accSize - 1; i >= 0; i--)
		{
			p += ratio;
			if (Main.DEBUG)
				Main._log.info("VAL: " + results[i * 3] + ", X: " + results[i * 3 + 1] + ", Y: " + results[i * 3 + 2]);
			drawCircle(results[i * 3], results[i * 3 + 1], results[i * 3 + 2]);
			centerCords = new Point(results[i * 3 + 1], results[i * 3 + 2]);
			value = results[i * 3];
		}
		return output;
	}

	public Point centerCords;

	private void setPixel(int value, int xPos, int yPos)
	{
		int p = ((yPos * width) + xPos);
		// sprawdź, czy pozycja nie wychodzi poza obraz
		if (p < 0 || p >= output.length)
			return;
		// ustaw kolor pixela na "value"
		output[(yPos * width) + xPos] = 0xff000000 | (value << 16 | value << 8 | value);
	}

	private void drawCircle(int pix, int xCenter, int yCenter)
	{
		// funkcja rysująca okrąg
		pix = 250;

		int x, y, r2;
		int radius = r;
		r2 = r * r;
		setPixel(pix, xCenter, yCenter + radius);
		setPixel(pix, xCenter, yCenter - radius);
		setPixel(pix, xCenter + radius, yCenter);
		setPixel(pix, xCenter - radius, yCenter);

		y = radius;
		x = 1;
		y = (int)(Math.sqrt(r2 - 1) + 0.5);
		while (x < y)
		{
			setPixel(pix, xCenter + x, yCenter + y);
			setPixel(pix, xCenter + x, yCenter - y);
			setPixel(pix, xCenter - x, yCenter + y);
			setPixel(pix, xCenter - x, yCenter - y);
			setPixel(pix, xCenter + y, yCenter + x);
			setPixel(pix, xCenter + y, yCenter - x);
			setPixel(pix, xCenter - y, yCenter + x);
			setPixel(pix, xCenter - y, yCenter - x);
			x += 1;
			y = (int)(Math.sqrt(r2 - x * x) + 0.5);
		}
		if (x == y)
		{
			setPixel(pix, xCenter + x, yCenter + y);
			setPixel(pix, xCenter + x, yCenter - y);
			setPixel(pix, xCenter - x, yCenter + y);
			setPixel(pix, xCenter - x, yCenter - y);
		}
	}

	public int[] getAcc()
	{
		return acc;
	}

	public int getProgress()
	{
		return (int)p;
	}
}
