/*
 * Author: Chris Campbell - www.iforce2d.net
 */

#include "VID_GLViewController.h"
#include "GLES1DebugDraw.h"

#ifndef DEGTORAD
#define DEGTORAD 0.0174532925199432957f
#define RADTODEG 57.295779513082320876f
#endif

/*
 * To enable blending for these rendering routines, do:
 * glEnable(GL_BLEND);
 * glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
*/

void GLES1DebugDraw::DrawPoint(const b2Vec2& p, float32 size, const b2Color& color)
{
	glPointSize(size);
	glBegin(GL_POINTS);
	glColor3f(color.r, color.g, color.b);
	glVertex2f(p.x, p.y);
	glEnd();
	glPointSize(1.0f);
}

float currentscale = 1; // amount of pixels that corresponds to one world unit, needed to use glPointSize correctly
float smoothstep(float x) { return x * x * (3 - 2 * x); }

void GLES1DebugDraw::DrawParticles(const b2Vec2 *centers, float32 radius, const b2ParticleColor *colors, int32 count)
{
	//LOGD("GLES1DebugDraw::DrawParticles");
	static unsigned int particle_texture = 0;
	
	if (!particle_texture ||
		!glIsTexture(particle_texture)) // Android deletes textures upon sleep etc.
	{
		// generate a "gaussian blob" texture procedurally
		glGenTextures(1, &particle_texture);
		b2Assert(particle_texture);
		const int TSIZE = 64;
		unsigned char tex[TSIZE][TSIZE][4];
		for (int y = 0; y < TSIZE; y++)
		{
			for (int x = 0; x < TSIZE; x++)
			{
				float fx = (x + 0.5f) / TSIZE * 2 - 1;
				float fy = (y + 0.5f) / TSIZE * 2 - 1;
				float dist = sqrtf(fx * fx + fy * fy);
				unsigned char intensity = (unsigned char)(dist <= 1 ? smoothstep(1 - dist) * 255 : 0);
				tex[y][x][0] = tex[y][x][1] = tex[y][x][2] = 128;
				tex[y][x][3] = intensity;
			}
		}
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, particle_texture);
#ifdef __ANDROID__
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
#endif
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TSIZE, TSIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, tex);
		
		glDisable(GL_TEXTURE_2D);
		
		glEnable(GL_POINT_SMOOTH);
	}
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, particle_texture);
	
#ifdef __ANDROID__
	glEnable(GL_POINT_SPRITE_OES);
	glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
	const float particle_size_multiplier = 3;  // because of falloff
	const float global_alpha = 1;  // none, baked in texture
#else
	/*
	 // normally this is how we'd enable them on desktop OpenGL,
	 // but for some reason this is not applying textures, so we use alpha instead
	 glEnable(GL_POINT_SPRITE);
	 glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);
	 */
	const float particle_size_multiplier = 300;  // no falloff
	const float global_alpha = 0.35f;  // instead of texture
#endif

	glPointSize(radius * currentscale * particle_size_multiplier);
	
	glEnable(GL_BLEND);
	//glBlendFunc(GL_SRC_ALPHA, GL_ONE);

	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, &centers[0].x);
	if (colors)
	{
#ifndef __ANDROID__
		// hack to render with proper alpha on desktop for Testbed
		b2ParticleColor * mcolors = const_cast<b2ParticleColor *>(colors);
		for (int i = 0; i < count; i++)
		{
			mcolors[i].a = static_cast<uint8>(200); //global_alpha * 255);
		}
#endif
		glEnableClientState(GL_COLOR_ARRAY);
		glColorPointer(4, GL_UNSIGNED_BYTE, 0, &colors[0].r);
	}
	else
	{
		glColor4f(1, 1, 1, 1.0f); //global_alpha);
	}

	glColor4f(1, 1, 1, 0.8f); //global_alpha);

	glDrawArrays(GL_POINTS, 0, count);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	if (colors) glDisableClientState(GL_COLOR_ARRAY);
	
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
#ifdef __ANDROID__
	glDisable(GL_POINT_SPRITE_OES);
#endif
		
}

void GLES1DebugDraw::DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
{
//	LOGD("DrawPolygon");
    //set up vertex array
    GLfloat glverts[16]; //allow for polygons up to 8 vertices
    glVertexPointer(2, GL_FLOAT, 0, glverts); //tell OpenGL where to find vertices
    glEnableClientState(GL_VERTEX_ARRAY); //use vertices in subsequent calls to glDrawArrays

    //fill in vertex positions as directed by Box2D
    for (int i = 0; i < vertexCount; i++) {
		glverts[i*2]   = vertices[i].x;
		glverts[i*2+1] = vertices[i].y;
    }

    //edge lines
	glColor4f( color.r, color.g, color.b, 1 );
    glDrawArrays(GL_LINE_LOOP, 0, vertexCount);
}

void GLES1DebugDraw::DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
{
	//LOGD("DrawSolidPolygon");
    GLfloat glverts[16];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

    for (int i = 0; i < vertexCount; i++)
	{
		//LOGD("i=%3d x=%3.2f y=%3.2f", i, vertices[i].x, vertices[i].y);
		glverts[i*2]   = vertices[i].x;
		glverts[i*2+1] = vertices[i].y;
    }

    //solid area
    glColor4f( color.r, color.g, color.b, 0.5f );
    glDrawArrays(GL_TRIANGLE_FAN, 0, vertexCount);

    //edge lines
	glColor4f( 1.0f, 1.0f, 1.0f, 1.0f); //color.r, color.g, color.b, 1 );
	glDrawArrays(GL_LINE_LOOP, 0, vertexCount);
}

void GLES1DebugDraw::DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color)
{
//	LOGD("DrawCircle");
	const int numCircleVerts = 48;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = sinf(angle)*radius;
		glverts[i*2+1] = cosf(angle)*radius;
	}

	glPushMatrix();
	glTranslatef(center.x, center.y, 0);

    //edge lines
	glColor4f(color.r, color.g, color.b, 1);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);

	glPopMatrix();
}

void GLES1DebugDraw::DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color)
{
//	LOGD("DrawSolidCircle");
	const int numCircleVerts = 48;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = sinf(angle)*radius;
		glverts[i*2+1] = cosf(angle)*radius;
	}

	glPushMatrix();
	glTranslatef(center.x, center.y, 0);

    //solid area
	glColor4f(color.r, color.g, color.b, 0.5f);
	glDrawArrays(GL_TRIANGLE_FAN, 0, numCircleVerts);

    //edge lines
	glColor4f(color.r, color.g, color.b, 1);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);

	b2Vec2 p1(0,0);
	b2Vec2 p2 = radius * axis;
	DrawSegment(p1, p2, color);

	glPopMatrix();
}

void GLES1DebugDraw::DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color)
{
//	LOGD("DrawSegment");
	GLfloat glverts[4];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

    glverts[0] = p1.x;
	glverts[1] = p1.y;
    glverts[2] = p2.x;
	glverts[3] = p2.y;

    //edge lines
	glColor4f( color.r, color.g, color.b, 1 );
    glDrawArrays(GL_LINES, 0, 2);
}





