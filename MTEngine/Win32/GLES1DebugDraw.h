/*
 * Author: Chris Campbell - www.iforce2d.net
 */

#ifndef _GLES1DEBUGDRAW_H_
#define _GLES1DEBUGDRAW_H_

#include <Box2D/Box2D.h>

class GLES1DebugDraw : public b2Draw
{
public:
    void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color);
    void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color);
    void DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color);
    void DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color);
    void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color);
    void DrawTransform(const b2Transform& xf) {}
	void DrawParticles(const b2Vec2 *centers, float32 radius, const b2ParticleColor *colors, int32 count);
	void DrawPoint(const b2Vec2& p, float32 size, const b2Color& color);
};

#endif
//_GLES1DEBUGDRAW_H_
