#include "SYS_Defs.h"
#include "MTH_MTRand.h"
#include "mtrand.h"
#include "DBG_Log.h"
#include "SYS_Main.h"

float mtrandVals[1024] = {
	0.07507f,  0.37413f,  0.58486f,  0.10185f,  0.74356f,  0.37871f,  0.26288f,  0.88866f,  0.48799f,  0.74493f,  0.45391f,  0.86940f,  0.10829f,  0.41725f,  0.88531f,  0.63399f,  0.07418f,  0.97492f,  0.48072f,  0.47906f,  0.58078f,  0.11470f,  0.80928f,  0.47876f,  0.69976f,  0.88739f,  0.38404f,  0.74890f,  0.97006f,  0.56591f,  0.32925f,  0.14472f,  0.23599f,  0.78922f,  0.40364f,  0.05505f,  0.30373f,  0.95623f,  0.01900f,  0.68724f,  0.27329f,  0.34585f,  0.52924f,  0.25655f,  0.89276f,  0.50644f,  0.57865f,  0.22353f,  0.72367f,  0.42680f,  0.16871f,  0.38587f,  0.23974f,  0.28974f,  0.90342f,  0.24171f,  0.59436f,  0.27163f,  0.62018f,  0.01875f,  0.83878f,  0.62573f,  0.61210f,  0.74685f,  0.23794f,  0.58599f,  0.68807f,  0.92128f,  0.59674f,  0.36597f,  0.53582f,  0.75618f,  0.66540f,  0.19664f,  0.88456f,  0.63068f,  0.50580f,  0.50330f,  0.69303f,  0.76095f,  0.01318f,  0.98843f,  0.13811f,  0.03555f,  0.48772f,  0.06045f,  0.85230f,  0.57400f,  0.11901f,  0.38535f,  0.07319f,  0.60803f,  0.64685f,  0.73488f,  0.23411f,  0.59118f,  0.22095f,  0.84259f,  0.44896f,  0.74036f,  0.80297f,  0.24808f,  0.88792f,  0.92614f,  0.91902f,  0.60478f,  0.39530f,  0.61453f,  0.41778f,  0.09934f,  0.06460f,  0.79472f,  0.74131f,  0.96697f,  0.21699f,  0.03256f,  0.69540f,  0.23186f,  0.92879f,  0.09427f,  0.51662f,  0.83163f,  0.89299f,  0.11614f,  0.08455f,  0.92032f,  0.96148f,  0.74529f,  0.64659f,  0.48926f,  0.95441f,  0.58017f,  0.98876f,  0.23760f,  0.80714f,  0.10189f,  0.29990f,  0.11810f,  0.65031f,  0.11500f,  0.38318f,  0.37428f,  0.45231f,  0.39618f,  0.01836f,  0.46137f,  0.59675f,  0.14370f,  0.92305f,  0.27054f,  0.81727f,  0.07578f,  0.30323f,  0.68011f,  0.72159f,  0.91215f,  0.29576f,  0.29741f,  0.03754f,  0.39452f,  0.11466f,  0.06608f,  0.88186f,  0.01141f,  0.73617f,  0.66247f,  0.20244f,  0.27342f,  0.89394f,  0.66927f,  0.62022f,  0.67833f,  0.01726f,  0.76859f,  0.51083f,  0.34758f,  0.72370f,  0.86775f,  0.82914f,  0.32612f,  0.13771f,  0.04046f,  0.08224f,  0.43806f,  0.20686f,  0.42177f,  0.44423f,  0.45313f,  0.58400f,  0.96874f,  0.56709f,  0.22559f,  0.24566f,  0.12859f,  0.52712f,  0.36556f,  0.69571f,  0.49253f,  0.83666f,  0.61118f,  0.25139f,  0.47538f,  0.46612f,  0.86992f,  0.22524f,  0.09858f,  0.69284f,  0.42344f,  0.24244f,  0.13089f,  0.45861f,  0.52684f,  0.86232f,  0.51601f,  0.60021f,  0.71552f,  0.59139f,  0.53448f,  0.95175f,  0.33158f,  0.08522f,  0.87226f,  0.99956f,  0.81355f,  0.61198f,  0.12746f,  0.80691f,  0.15068f,  0.80254f,  0.22629f,  0.62646f,  0.42527f,  0.22090f,  0.21025f,  0.31893f,  0.84974f,  0.51663f,  0.92654f,  0.15454f,  0.34290f,  0.60938f,  0.75139f,  0.72486f,  0.05322f,  0.27193f,  0.61029f,  0.96056f,  0.93511f,  0.34197f,  0.28138f,  0.74036f,  0.41949f,  0.36506f,  0.01494f,  0.60429f,  0.77427f,  0.80748f,  0.38016f,  0.97587f,  0.82886f,  0.76623f,  0.51831f,  0.08692f,  0.53745f,  0.73962f,  0.53682f,  0.77115f,  0.06740f,  0.91458f,  0.80824f,  0.29506f,  0.10256f,  0.25877f,  0.32792f,  0.27176f,  0.22274f,  0.04593f,  0.31127f,  0.90261f,  0.29810f,  0.92190f,  0.15481f,  0.94258f,  0.62286f,  0.49085f,  0.25780f,  0.35405f,  0.02320f,  0.23869f,  0.27044f,  0.01548f,  0.20933f,  0.62278f,  0.13436f,  0.70237f,  0.06762f,  0.95335f,  0.01530f,  0.39200f,  0.17278f,  0.61876f,  0.78536f,  0.38376f,  0.87951f,  0.02706f,  0.95287f,  0.14089f,  0.64714f,  0.74002f,  0.99984f,  0.23529f,  0.18023f,  0.50377f,  0.02275f,  0.69219f,  0.77329f,  0.08352f,  0.53408f,  0.30620f,  0.78249f,  0.22394f,  0.92770f,  0.45743f,  0.57637f,  0.02083f,  0.07076f,  0.18265f,  0.53304f,  0.52164f,  0.89027f,  0.63224f,  0.20944f,  0.20408f,  0.54051f,  0.28079f,  0.39297f,  0.50971f,  0.63443f,  0.03176f,  0.91352f,  0.41838f,  0.11229f,  0.68569f,  0.23881f,  0.46023f,  0.78456f,  0.39652f,  0.09916f,  0.93062f,  0.07773f,  0.94077f,  0.54344f,  0.60177f,  0.08561f,  0.79256f,  0.74776f,  0.73582f,  0.80306f,  0.32524f,  0.52302f,  0.61257f,  0.15467f,  0.73545f,  0.95987f,  0.10702f,  0.44294f,  0.35337f,  0.60879f,  0.57612f,  0.49167f,  0.68689f,  0.87961f,  0.72210f,  0.74958f,  0.30760f,  0.43939f,  0.53919f,  0.01212f,  0.38395f,  0.19598f,  0.25421f,  0.49963f,  0.99092f,  0.45676f,  0.73477f,  0.03759f,  0.68189f,  0.76039f,  0.60160f,  0.10599f,  0.42713f,  0.35408f,  0.73649f,  0.34782f,  0.40771f,  0.78504f,  0.59421f,  0.90937f,  0.72566f,  0.19648f,  0.83105f,  0.93403f,  0.34634f,  0.18296f,  0.75621f,  0.29910f,  0.02707f,  0.78837f,  0.87301f,  0.31137f,  0.75889f,  0.30809f,  0.13784f,  0.83160f,  0.16523f,  0.57847f,  0.33375f,  0.99880f,  0.02739f,  0.76485f,  0.89273f,  0.28452f,  0.70204f,  0.72942f,  0.72233f,  0.33808f,  0.67050f,  0.73056f,  0.37247f,  0.03922f,  0.72482f,  0.10498f,  0.02688f,  0.32444f,  0.51140f,  0.09895f,  0.92125f,  0.93054f,  0.36208f,  0.27727f,  0.31352f,  0.79110f,  0.65446f,  0.12878f,  0.17013f,  0.80463f,  0.03192f,  0.24024f,  0.08536f,  0.47900f,  0.21843f,  0.12133f,  0.88554f,  0.14691f,  0.04100f,  0.45438f,  0.89725f,  0.03057f,  0.92110f,  0.13239f,  0.34441f,  0.11131f,  0.20557f,  0.57832f,  0.88435f,  0.43565f,  0.75422f,  0.01093f,  0.51641f,  0.24040f,  0.09245f,  0.25067f,  0.24775f,  0.91663f,  0.60974f,  0.05652f,  0.26126f,  0.38790f,  0.04587f,  0.01502f,  0.54318f,  0.00483f,  0.29411f,  0.12734f,  0.46199f,  0.88476f,  0.05038f,  0.75316f,  0.15922f,  0.22875f,  0.22266f,  0.45240f,  0.71716f,  0.22285f,  0.67259f,  0.12382f,  0.04097f,  0.85342f,  0.60427f,  0.95318f,  0.41374f,  0.73685f,  0.27848f,  0.51966f,  0.68038f,  0.67672f,  0.30928f,  0.16950f,  0.76628f,  0.79787f,  0.71161f,  0.48814f,  0.40844f,  0.24774f,  0.05788f,  0.22624f,  0.72566f,  0.98294f,  0.59867f,  0.94801f,  0.97877f,  0.13988f,  0.85955f,  0.02619f,  0.08714f,  0.36575f,  0.36444f,  0.40805f,  0.75392f,  0.32909f,  0.23174f,  0.33710f,  0.39125f,  0.76712f,  0.88023f,  0.26102f,  0.15912f,  0.23605f,  0.95686f,  0.80115f,  0.90927f,  0.71740f,  0.70880f,  0.77895f,  0.63491f,  0.72174f,  0.73081f,  0.07254f,  0.26659f,  0.37015f,  0.57398f,  0.10835f,  0.90823f,  0.46756f,  0.41416f,  0.95439f,  0.15715f,  0.52761f,  0.19283f,  0.02734f,  0.59395f,  0.78453f,  0.81284f,  0.37606f,  0.69333f,  0.90732f,  0.32780f,  0.53272f,  0.55561f,  0.02521f,  0.16633f,  0.71211f,  0.99400f,  0.43579f,  0.08191f,  0.09586f,  0.65430f,  0.89725f,  0.49981f,  0.73924f,  0.17461f,  0.79937f,  0.34295f,  0.49643f,  0.39840f,  0.15430f,  0.60952f,  0.79731f,  0.38302f,  0.17181f,  0.57452f,  0.66167f,  0.06338f,  0.83171f,  0.29083f,  0.57841f,  0.72482f,  0.96591f,  0.41684f,  0.71253f,  0.84725f,  0.53872f,  0.67406f,  0.31207f,  0.47930f,  0.17345f,  0.69061f,  0.13258f,  0.58735f,  0.76652f,  0.84564f,  0.39219f,  0.86002f,  0.50464f,  0.69754f,  0.15025f,  0.94542f,  0.94727f,  0.77245f,  0.35336f,  0.37198f,  0.48392f,  0.65423f,  0.74143f,  0.92739f,  0.30534f,  0.54419f,  0.76946f,  0.24759f,  0.79728f,  0.48260f,  0.86829f,  0.13538f,  0.38988f,  0.15857f,  0.42785f,  0.81136f,  0.77904f,  0.27228f,  0.20646f,  0.16668f,  0.32791f,  0.75531f,  0.93679f,  0.30517f,  0.40303f,  0.27525f,  0.08729f,  0.39627f,  0.64697f,  0.04240f,  0.10275f,  0.14466f,  0.09370f,  0.09079f,  0.96485f,  0.87160f,  0.49049f,  0.44458f,  0.88510f,  0.05218f,  0.48384f,  0.53471f,  0.89184f,  0.55451f,  0.58462f,  0.71359f,  0.41676f,  0.57932f,  0.56011f,  0.43992f,  0.02627f,  0.43657f,  0.16693f,  0.70511f,  0.49436f,  0.47928f,  0.83354f,  0.19369f,  0.63627f,  0.85783f,  0.95767f,  0.76414f,  0.55441f,  0.22711f,  0.90399f,  0.97845f,  0.36481f,  0.16823f,  0.71429f,  0.92899f,  0.29422f,  0.98298f,  0.40838f,  0.75743f,  0.08147f,  0.98440f,  0.16157f,  0.09775f,  0.49525f,  0.81061f,  0.05945f,  0.12306f,  0.45364f,  0.59760f,  0.39542f,  0.27230f,  0.23840f,  0.08295f,  0.62769f,  0.40235f,  0.10561f,  0.88725f,  0.89916f,  0.93537f,  0.79851f,  0.58856f,  0.03842f,  0.49970f,  0.82017f,  0.01905f,  0.42136f,  0.71342f,  0.53220f,  0.73512f,  0.91837f,  0.80241f,  0.13548f,  0.38330f,  0.76907f,  0.23207f,  0.85066f,  0.59769f,  0.71580f,  0.27731f,  0.39708f,  0.24903f,  0.47283f,  0.99612f,  0.42861f,  0.91720f,  0.56342f,  0.15884f,  0.01430f,  0.76144f,  0.56350f,  0.33625f,  0.53146f,  0.28812f,  0.67679f,  0.53420f,  0.77864f,  0.38031f,  0.87744f,  0.02121f,  0.31244f,  0.86098f,  0.51607f,  0.51173f,  0.81370f,  0.83808f,  0.65093f,  0.62359f,  0.55486f,  0.90383f,  0.40253f,  0.70062f,  0.63290f,  0.24448f,  0.17763f,  0.07952f,  0.75348f,  0.47860f,  0.58085f,  0.39707f,  0.92976f,  0.73746f,  0.40551f,  0.46363f,  0.00228f,  0.38962f,  0.29077f,  0.39421f,  0.11600f,  0.54833f,  0.66754f,  0.25811f,  0.63084f,  0.34423f,  0.61351f,  0.62857f,  0.60287f,  0.91201f,  0.31529f,  0.32965f,  0.39711f,  0.88179f,  0.85447f,  0.42468f,  0.71919f,  0.63087f,  0.73440f,  0.96235f,  0.86008f,  0.88307f,  0.10081f,  0.71432f,  0.23597f,  0.23848f,  0.90194f,  0.84885f,  0.82772f,  0.18834f,  0.64689f,  0.10727f,  0.89780f,  0.69933f,  0.21440f,  0.58883f,  0.29894f,  0.39954f,  0.97807f,  0.52250f,  0.34925f,  0.66642f,  0.72009f,  0.71747f,  0.83295f,  0.40971f,  0.30341f,  0.73711f,  0.55206f,  0.19102f,  0.17063f,  0.01752f,  0.07715f,  0.26815f,  0.79387f,  0.63878f,  0.01443f,  0.93122f,  0.93574f,  0.01769f,  0.33928f,  0.25109f,  0.01765f,  0.22538f,  0.12427f,  0.27246f,  0.79717f,  0.20858f,  0.70254f,  0.24368f,  0.92862f,  0.53319f,  0.97686f,  0.23415f,  0.59290f,  0.53824f,  0.97555f,  0.79424f,  0.64687f,  0.00550f,  0.12926f,  0.93018f,  0.12184f,  0.50901f,  0.17594f,  0.37857f,  0.32796f,  0.12426f,  0.97777f,  0.55815f,  0.63451f,  0.11722f,  0.54171f,  0.45424f,  0.06448f,  0.03706f,  0.04509f,  0.53924f,  0.41389f,  0.19391f,  0.89914f,  0.19245f,  0.38119f,  0.36106f,  0.62864f,  0.78458f,  0.87233f,  0.89826f,  0.76619f,  0.93692f,  0.69327f,  0.46089f,  0.28766f,  0.58259f,  0.70418f,  0.46561f,  0.22369f,  0.72188f,  0.90971f,  0.94667f,  0.67067f,  0.71842f,  0.07049f,  0.11343f,  0.82516f,  0.07694f,  0.64872f,  0.72868f,  0.06691f,  0.88600f,  0.33231f,  0.38320f,  0.55922f,  0.94218f,  0.35665f,  0.00297f,  0.31014f,  0.07212f,  0.29650f,  0.46813f,  0.66828f,  0.50249f,  0.59714f,  0.62105f,  0.05427f,  0.99258f,  0.71966f,  0.56197f,  0.93161f,  0.83124f,  0.98789f,  0.25775f,  0.78273f,  0.37189f,  0.27559f,  0.17141f,  0.45783f,  0.61392f,  0.54521f,  0.51752f,  0.51830f,  0.01635f,  0.95222f,  0.11421f,  0.28485f,  0.03168f,  0.91822f,  0.09729f,  0.93824f,  0.84691f,  0.53368f,  0.33550f,  0.83747f,  0.68343f,  0.31766f,  0.16292f,  0.85344f,  0.65000f,  0.19512f,  0.50984f,  0.72315f,  0.08524f,  0.01288f,  0.09313f,  0.96360f,  0.60615f,  0.91399f,  0.04503f,  0.15077f,  0.96100f,  0.63455f,  0.23240f,  0.52219f,  0.85294f,  0.57450f,  0.31025f,  0.40660f,  0.61609f,  0.31064f,  0.53253f,  0.85739f,  0.53833f,  0.40529f,  0.82834f,  0.78467f,  0.72544f,  0.12017f,  0.80232f,  0.88456f,  0.37825f,  0.50676f,  0.82397f,  0.57027f,  0.17165f,  0.52002f,  0.35047f,  0.71180f,  0.49237f,  0.99060f,  0.28066f,  0.20584f,  0.21749f,  0.31882f,  0.63722f,  0.02836f,  0.54524f,  0.93637f,  0.06371f,  0.52347f,  0.01632f,  0.89131f,  0.18690f,  0.78764f,  0.63644f,  0.80867f,  0.18472f,  0.22038f,  0.02120f,  0.70878f,  0.82658f,  0.37907f };


void MTH_TestMTRand()
{
//	LOGM("MTH_TestMTRand: init");
//	MTRand drand(1318);
//
//	//FILE *fp = fopen("TestMTRand", "wb");
//	for (u16 i = 0; i < 1024; i++)
//	{
//		float v = (float)drand();
//		//fprintf(fp, " %3.5ff, ", v);
//
//		if ( v - mtrandVals[i] > 0.00001f)
//		{
//			SYS_FatalExit("MTH_TestMTRand: failed on %d %10.8f != %10.8f", v, mtrandVals);
//		}
//	}
//	//fclose(fp);
//
////	for (u16 i = 0; i < 10000; i++)
////		LOGD("%10.8f", drand.Range(-10, 10));
//
//	LOGM("MTH_TestMTRand: correct");

}



/*
 ;---------------------------------------------------------------------------
 ;pseudo-random routine, value in random+1 (akku also) and random
 ;---------------------------------------------------------------------------
 getrandom:
 
 lda random+1
 sta temp1
 lda random
 asl a
 rol temp1
 asl a
 rol temp1
 clc
 adc random
 pha
 lda temp1
 adc random+1
 sta random+1
 pla
 adc #$11
 sta random
 lda random+1
 adc #$36
 sta random+1
 
 rts
 
 temp1:   .byte $5a
 random:  .byte %10011101,%01011011
 */

/*
 Newsgroups: comp.sys.cbm
 Subject: Re: C64 Random Generator?
 Summary:
 Expires:
 References: <Pine.GSO.3.95.980424085552.16245A-100000@wartburg.kom.auc.dk> <Pine.SOL.3.95.980424134847.17282G-100000@hobbes.dai.ed.ac.uk> <6hq9sp$ok7@news.acns.nwu.edu> <6hqisi$qg6@examiner.concentric.net>
 Sender:
 Followup-To:
 Reply-To: sjudd@nwu.edu (Stephen Judd)
 Distribution:
 Organization: Northwestern University, Evanston, IL
 Keywords:
 Cc:
 
 In article <6hqisi$qg6@examiner.concentric.net>,
 Cameron Kaiser  <cdkaiser@delete.these.four.words.concentric.net> wrote:
 >judd@merle.acns.nwu.edu (Stephen Judd) writes:
 >
 >>Another method I have seen is the "middle-squares" process: if x is
 >>an m-digit random number, then the next number is given by the middle
 >>m digits of x^2 (which is of size 2m).  Anyways, as you can see it
 
 The "it" above refers to any random number generation algorithm, btw.
 
 >>is a deterministic process, and if you start from the same initial
 >>value (the "seed"), then you will generate the same sequence.  This
 >>isn't a bad thing, btw -- it means you can reproduce results, initial
 >>conditions, etc.
 >
 >I think this is the one proposed by von Neumann, and someone demonstrated a
 >seed that when plugged into the von Neumann generator will devolve to zero
 >after only a few cycles. Apparently there are many such seeds, so this
 >generator is effectively useless.
 
 I read about this method in the paper "Equation of State Calculations by
 Fast Computing Machines", by Nick Metropolis, Edward Teller, Marshall
 Rosenbluth, Arianna Rosenbluth, and Augusta Teller (Journal Chem Phys.,
 v21 No. 6, June 1953).  "Useless" is a very strong adjective; therefore
 I strongly disagree with it.
 
 >>Also, RND(-X) swaps bytes in the random number ($61<->$64 and
 >>$62<->$63 I believe) -- silly.
 >
 >IIRC RND(-X) puts X as the seed. So RND(-TI) works well, provided you
 >consider the time a random number (but since it always starts at zero when
 >you turn the computer on it's less random than you think).
 
 Not quite.  Let's have a look-see:
 
 E097   20 2B BC   JSR $BC2B	;Get sign of function argument
 E09A   30 37      BMI $E0D3
 E09C   D0 20      BNE $E0BE
 
 E09E   20 F3 FF   JSR $FFF3	;If zero, initialize from CIA timers
 E0A1   86 22      STX $22
 E0A3   84 23      STY $23
 E0A5   A0 04      LDY #$04
 E0A7   B1 22      LDA ($22),Y
 E0A9   85 62      STA $62
 E0AB   C8         INY
 E0AC   B1 22      LDA ($22),Y
 E0AE   85 64      STA $64
 E0B0   A0 08      LDY #$08
 E0B2   B1 22      LDA ($22),Y
 E0B4   85 63      STA $63
 E0B6   C8         INY
 E0B7   B1 22      LDA ($22),Y
 E0B9   85 65      STA $65
 E0BB   4C E3 E0   JMP $E0E3
 
 E0BE   A9 8B      LDA #$8B	;If positive, copy iterate to FAC1 (from $8B)
 E0C0   A0 00      LDY #$00
 E0C2   20 A2 BB   JSR $BBA2
 E0C5   A9 8D      LDA #$8D	;Then multiply by num at $E08D (= 11879546)
 E0C7   A0 E0      LDY #$E0
 E0C9   20 28 BA   JSR $BA28	;Your favorite routine :)
 E0CC   A9 92      LDA #$92	;And add number at $E092 (= 3.927677739e-8)
 E0CE   A0 E0      LDY #$E0
 E0D0   20 67 B8   JSR $B867
 ;Entry point for RND(-X)
 E0D3   A6 65      LDX $65	;Do something dumb like reverse all the bytes
 E0D5   A5 62      LDA $62
 E0D7   85 65      STA $65
 E0D9   86 62      STX $62
 E0DB   A6 63      LDX $63
 E0DD   A5 64      LDA $64
 E0DF   85 63      STA $63
 E0E1   86 64      STX $64
 E0E3   A9 00      LDA #$00	;Make positive
 E0E5   85 66      STA $66
 E0E7   A5 61      LDA $61	;Do something dumb like use old exponent
 E0E9   85 70      STA $70	;as extra bits
 E0EB   A9 80      LDA #$80	;Set exponent to -1
 E0ED   85 61      STA $61
 E0EF   20 D7 B8   JSR $B8D7	;Normalize result (remove leading zeroes)
 E0F2   A2 8B      LDX #$8B	;(mark another correction in Mapping the 64...)
 E0F4   A0 00      LDY #$00
 E0F6   4C D4 BB   JMP $BBD4	;Store number at $008B
 
 As you can see, this is a pretty nutty algorithm.
 
 >>Now, what is relevant here is that some sequences are better than
 >>others!  The choice of a and m in a*x mod m affects the calculation
 >>quite significantly.  Ideally you want to generate every number
 >>in an interval (i.e. all numbers between 0 and 1 that the computer
 >>can represent), and you want the sequence to be evenly distributed.
 >
 >I disagree with this definition. I read 'even distribution' to say that
 >no number *should* appear more frequently than any other, but I consider it
 >random and acceptable for a random number generator to continually return 1,
 >as long as the generator depends nothing on the numbers before it. One has
 
 I'm really unclear about what you are saying.  I for one don't think
 x=1 is a particularly good random number generator, and I'm not even
 sure what the last "it" of the last sentence refers to.  Moreover,
 all random number generators use an iterative method.  I will try
 another explanation.
 
 First, an anecdote from "Numerical Recipies".  One of the authors had
 found that the IBM "RANDU" random number generator didn't work very well.
 He called customer support, and they said he had misused their generator:
 "We guarantee that each number is random individually, but we don't
 guarantee that more than one of them is random."
 
 There's an important moral here: "random" is really a relative quantity.
 That is, the important thing is the _sequence_ of numbers that a
 random generator produces.  The sequence should be very long, and be
 totally uncorrelated.
 
 So now consider a generator like x=f(x), and for simplicity consider x to
 be an 8-bit number.  Eventually the generator will hit a number it has
 already generated, at which point the sequence will repeat.  Naturally one
 would like the sequence to be as long as possible -- 23 233 23 233 ...
 isn't a very useful sequence.  Since x is an 8-bit number, the longest
 possible sequence has all 256 numbers.  This is one reason to generate
 every number in the interval -- it makes sure the sequence has a long
 period.
 
 Moreover, the sequence should be uniformly distributed throughout the
 interval -- not only should no single number be more probable than
 any other, but no group of numbers should be more probable than
 any other.  For example, numbers between 20 and 30 shouldn't be more
 probable than numbers between 241 and 251.  Note that sometimes you
 do want a non-uniform distribution -- say, a Gaussian distribution
 of random numbers -- but these are invariably generated from a
 uniform distribution.
 
 Finally, the sequence should be uncorrelated.  The sequence  0 1 2 3 ...
 is uniform and has a long period, but certainly isn't random.  Here's
 another sequence:
 
 142 3 84 242 198 30 34 204 239 77 ...
 
 It looks reasonably random.  In fact, I generated it using a=a+2*pi/4.321
 x=128*(1+cos(a)).  So it takes some real work to ensure that a sequence
 really is random.  Much of this falls under the broad rubric of "Time
 Series Analysis" -- you've got a sensor sending numbers to you, and want
 to know if the resulting time series is chaotic, nonlinear, deterministic,
 correlated, etc.  This is also a subject I don't know much about.  For
 random numbers, though, there are several tests available.  Knuth has
 one in vol. 2 of "The Art of Computer Programming", and I'm sure that
 Numerical Recipies references some of the more recent schemes.
 
 It is worth emphasizing that what is important here is that the _sequence_
 is random.  Making sure that "each number is random individually" doesn't
 mean anything.  This is why doing things like swapping bytes is such
 a bad idea -- it doesn't make the number "more random", but it does
 wreck the sequence.  It's also why doing things like reading from
 SID four times to make a new floating point number never work well.
 In fact, even reading from SID is probably a bad idea, in terms of
 generating a sequence with the above properties (and at worst, you
 might sample at some period of the random number generator -- of
 course it's very improbable :), but it gives a flavor of the problems).
 
 Why is all of this important?  For most computer science applications,
 it isn't.  For most scientific applications, it is terribly important.
 Cute tricks like swapping bytes can be absolutely devastating to e.g.
 a Monte-Carlo integrator.  Unless that sequence has the right properties,
 you just aren't simulating nature.  A computer jock without any
 mathematical or scientific background is to be distrusted absolutely!
 (For scientific applications anyways.  If it makes you feel better,
 don't trust me to write a database :).
 
 >Someone (Larry Wall?) likes this as a good source of random numbers:
 >
 >% ps -auxww | compress | compress > random
 >
 >Read random bytes from the file random, and run again to re-seed. Hope
 >you have a busy system ;-)
 
 Looks neat, but I bet it fails the spectral tests -- i.e. probably
 fine for CS applications, but death for any Real application :).
 
 BTW, looks like you're on a Sun -- those ps options have different
 meanings on different computers.
 
 >F-Secure ssh for Windows has you move your mouse around in circular motion
 >and measures the eccentricity; a lot of PGP implementations just have you bang
 >on the keyboard.
 
 It would be interesting to see if these pass the tests.  I also wonder
 what effect generators have on the underlying security.  I have zero
 experience in this area -- it's a serious question!
 
 S/KEY uses a phrase typed in from the keyboard, so my guess is
 "not much".
 
 >>Any other questions? :)
 >
 >Why is the earth round? :-)
 
 Because a truncated earth wouldn't give as good of a result.
 
 evetS-
 */
