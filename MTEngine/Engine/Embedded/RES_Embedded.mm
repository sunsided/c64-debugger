#include "RES_Embedded.h"
#include "RES_ResourceManager.h"
#include "RES_DeployFile.h"

// default embedded data
#include "console_plain_gfx.h"
#include "default_font_fnt.h"
#include "default_font_gfx.h"

#include "icon_new_gfx.h"
#include "icon_clear_gfx.h"
#include "icon_open_gfx.h"
#include "icon_export_gfx.h"
#include "icon_import_gfx.h"
#include "icon_tool_rectangle_gfx.h"
#include "icon_tool_pen_gfx.h"
#include "icon_tool_line_gfx.h"
#include "icon_tool_fill_gfx.h"
#include "icon_tool_dither_gfx.h"
#include "icon_tool_circle_gfx.h"
#include "icon_tool_brush_square_gfx.h"
#include "icon_tool_brush_circle_gfx.h"
#include "icon_settings_gfx.h"
#include "icon_save_gfx.h"
#include "icon_close_gfx.h"
#include "icon_small_export_gfx.h"
#include "icon_small_import_gfx.h"
//#include "icon_toolbox_import_gfx.h"
//#include "icon_toolbox_export_gfx.h"
#include "icon_raw_export_gfx.h"
#include "icon_raw_import_gfx.h"
#include "icon_tool_on_top_on_gfx.h"
#include "icon_tool_on_top_off_gfx.h"

void RES_InitEmbeddedData()
{
	LOGM("RES_InitEmbeddedData");
	
	RES_AddEmbeddedDataToDeploy("/Engine/console-plain", DEPLOY_FILE_TYPE_GFX, console_plain_gfx, console_plain_gfx_length);
	RES_AddEmbeddedDataToDeploy("/Engine/default-font", DEPLOY_FILE_TYPE_FONT, default_font_fnt, default_font_fnt_length);
	RES_AddEmbeddedDataToDeploy("/Engine/default-font", DEPLOY_FILE_TYPE_GFX, default_font_gfx, default_font_gfx_length);

	RES_AddEmbeddedDataToDeploy("/gfx/icon_new", DEPLOY_FILE_TYPE_GFX, ico_new_gfx, ico_new_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_clear", DEPLOY_FILE_TYPE_GFX, ico_clear_gfx, ico_clear_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_open", DEPLOY_FILE_TYPE_GFX, ico_open_gfx, ico_open_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_save", DEPLOY_FILE_TYPE_GFX, ico_save_gfx, ico_save_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_export", DEPLOY_FILE_TYPE_GFX, ico_export_gfx, ico_export_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_import", DEPLOY_FILE_TYPE_GFX, ico_import_gfx, ico_import_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_settings", DEPLOY_FILE_TYPE_GFX, ico_settings_gfx, ico_settings_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_rectangle", DEPLOY_FILE_TYPE_GFX, ico_tool_rectangle_gfx, ico_tool_rectangle_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_pen", DEPLOY_FILE_TYPE_GFX, ico_tool_pen_gfx, ico_tool_pen_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_line", DEPLOY_FILE_TYPE_GFX, ico_tool_line_gfx, ico_tool_line_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_fill", DEPLOY_FILE_TYPE_GFX, ico_tool_fill_gfx, ico_tool_fill_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_dither", DEPLOY_FILE_TYPE_GFX, ico_tool_dither_gfx, ico_tool_dither_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_circle", DEPLOY_FILE_TYPE_GFX, ico_tool_circle_gfx, ico_tool_circle_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_brush_square", DEPLOY_FILE_TYPE_GFX, ico_tool_brush_square_gfx, ico_tool_brush_square_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_brush_circle", DEPLOY_FILE_TYPE_GFX, ico_tool_brush_circle_gfx, ico_tool_brush_circle_gfx_length);

	RES_AddEmbeddedDataToDeploy("/gfx/icon_close", DEPLOY_FILE_TYPE_GFX, icon_close_gfx, icon_close_gfx_length);
	
//	RES_AddEmbeddedDataToDeploy("/gfx/icon_toolbox_export", DEPLOY_FILE_TYPE_GFX, icon_toolbox_export_gfx, icon_toolbox_export_gfx_length);
//	RES_AddEmbeddedDataToDeploy("/gfx/icon_toolbox_import", DEPLOY_FILE_TYPE_GFX, icon_toolbox_import_gfx, icon_toolbox_import_gfx_length);

	RES_AddEmbeddedDataToDeploy("/gfx/icon_raw_export", DEPLOY_FILE_TYPE_GFX, icon_raw_export_gfx, icon_raw_export_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_raw_import", DEPLOY_FILE_TYPE_GFX, icon_raw_import_gfx, icon_raw_import_gfx_length);

	RES_AddEmbeddedDataToDeploy("/gfx/icon_small_export", DEPLOY_FILE_TYPE_GFX, icon_small_export_gfx, icon_small_export_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_small_import", DEPLOY_FILE_TYPE_GFX, icon_small_import_gfx, icon_small_import_gfx_length);

	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_on_top_off", DEPLOY_FILE_TYPE_GFX, icon_tool_on_top_off_gfx, icon_tool_on_top_off_gfx_length);
	RES_AddEmbeddedDataToDeploy("/gfx/icon_tool_on_top_on", DEPLOY_FILE_TYPE_GFX, icon_tool_on_top_on_gfx, icon_tool_on_top_on_gfx_length);
}

