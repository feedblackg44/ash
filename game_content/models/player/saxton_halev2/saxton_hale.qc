// Created by Crowbar 0.29.0.0

$ModelName "player/saxton_halev2/saxton_hale.mdl"

$Model "hale" "saxton_hale_reference.smd" {

	eyeball "eye_right" "bip_head" -1.540000 -3.070003 79.379988 "models\player\saxton_halev2\eyeball_r" 1 4 "iris_unused" 0.63
	eyeball "eye_left" "bip_head" 1.540000 -3.070003 79.379988 "models\player\saxton_halev2\eyeball_l" 1 -4 "iris_unused" 0.63

	flexfile "saxton_hale.vta" 
	{
		defaultflex frame 0
		flex "CloseLidLo" frame 1
		flex "CloseLidUp" frame 2
		flex "WQ" frame 3
		flex "OO" frame 4
		flex "MB" frame 5
		flex "SH" frame 6
		flex "Y" frame 7
		flex "FV" frame 8
		flex "AH" frame 9
		flex "AE" frame 10
		flex "UH" frame 11
		flex "AW" frame 12
		flex "EE" frame 13
		flex "PP" frame 14
		flex "OH" frame 15
		flex "TH" frame 16
		flex "T" frame 17
		flex "ER" frame 18
		flex "DS" frame 19
		flex "GK" frame 20
		flex "N" frame 21
		flex "silence" frame 22
		flex "happySmall" frame 23
		flex "madUpper" frame 24
		flex "scaredUpper" frame 25
		flex "painBigUpper" frame 26
		flex "painSmallUpper" frame 27
		flex "happyBigUpper" frame 28
		flex "happySmallUpper" frame 29
		flex "mad" frame 30
		flex "specialAction01" frame 31
		flex "scared" frame 32
		flex "painBig" frame 33
		flex "painSmall" frame 34
		flex "happyBig" frame 35
		flex "specialAction01Upper" frame 36
	}

	flexcontroller CloseLidLo range 0 1 CloseLidLo
	flexcontroller CloseLidUp range 0 1 CloseLidUp
	flexcontroller WQ range 0 1 WQ
	flexcontroller OO range 0 1 OO
	flexcontroller MB range 0 1 MB
	flexcontroller SH range 0 1 SH
	flexcontroller Y range 0 1 Y
	flexcontroller FV range 0 1 FV
	flexcontroller AH range 0 1 AH
	flexcontroller AE range 0 1 AE
	flexcontroller UH range 0 1 UH
	flexcontroller AW range 0 1 AW
	flexcontroller EE range 0 1 EE
	flexcontroller PP range 0 1 PP
	flexcontroller OH range 0 1 OH
	flexcontroller TH range 0 1 TH
	flexcontroller T range 0 1 T
	flexcontroller ER range 0 1 ER
	flexcontroller DS range 0 1 DS
	flexcontroller GK range 0 1 GK
	flexcontroller N range 0 1 N
	flexcontroller silence range 0 1 silence
	flexcontroller happySmall range 0 1 happySmall
	flexcontroller madUpper range 0 1 madUpper
	flexcontroller defaultFaceUpper range 0 1 defaultFaceUpper
	flexcontroller scaredUpper range 0 1 scaredUpper
	flexcontroller painBigUpper range 0 1 painBigUpper
	flexcontroller painSmallUpper range 0 1 painSmallUpper
	flexcontroller happyBigUpper range 0 1 happyBigUpper
	flexcontroller happySmallUpper range 0 1 happySmallUpper
	flexcontroller mad range 0 1 mad
	flexcontroller specialAction01 range 0 1 specialAction01
	flexcontroller defaultFace range 0 1 defaultFace
	flexcontroller scared range 0 1 scared
	flexcontroller painBig range 0 1 painBig
	flexcontroller painSmall range 0 1 painSmall
	flexcontroller happyBig range 0 1 happyBig
	flexcontroller specialAction01Upper range 0 1 specialAction01Upper

	localvar defaultFaceUpper
	localvar defaultFace
	%CloseLidLo = CloseLidLo
	%CloseLidUp = CloseLidUp
	%WQ = WQ
	%OO = OO
	%MB = MB
	%SH = SH
	%Y = Y
	%FV = FV
	%AH = AH
	%AE = AE
	%UH = UH
	%AW = AW
	%EE = EE
	%PP = PP
	%OH = OH
	%TH = TH
	%T = T
	%ER = ER
	%DS = DS
	%GK = GK
	%N = N
	%silence = silence
	%happySmall = happySmall
	%madUpper = madUpper
	%defaultFaceUpper = defaultFaceUpper
	%scaredUpper = scaredUpper
	%painBigUpper = painBigUpper
	%painSmallUpper = painSmallUpper
	%happyBigUpper = happyBigUpper
	%happySmallUpper = happySmallUpper
	%mad = mad
	%specialAction01 = specialAction01
	%defaultFace = defaultFace
	%scared = scared
	%painBig = painBig
	%painSmall = painSmall
	%happyBig = happyBig
	%specialAction01Upper = specialAction01Upper
}

$LOD 10
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod1.smd"
}
$LOD 20
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod2.smd"
}
$LOD 30
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod3.smd"
}
$LOD 40
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod4.smd"
}
$LOD 50
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod5.smd"
}
$ShadowLOD
{
	replacemodel "saxton_hale_reference.smd" "saxton_hale_reference_lod6.smd"
}

$SurfaceProp "flesh"

$Contents "solid"

$EyePosition 78.62 0 0

$MaxEyeDeflection 90

$CDMaterials "models\player\saxton_halev2\"
$CDMaterials ""

$Attachment "eyes" "bip_head" 0 -4.18 -4.17 rotate 89.73 -90 0
$Attachment "righteye" "bip_head" -1.54 -4.15 -4.19 rotate 89.73 -90 0
$Attachment "lefteye" "bip_head" 1.54 -4.15 -4.19 rotate 89.73 -90 0
$Attachment "foot_L" "bip_foot_L" 0 0 0 rotate 0 0 0
$Attachment "foot_R" "bip_foot_R" 0 0 0 rotate 0 0 0
$Attachment "partyhat" "bip_head" 0 -9.52 -0.91 rotate 84 90 161
$Attachment "head" "bip_head" 0 -8.97 -0.49 rotate 87.52 -90 0
$Attachment "flag" "bip_spine_3" 1.42 5.01 8.82 rotate -3.7 10.88 -10.1

$CBox 0 0 0 0 0 0

$BBox -9.391 -25.466 -3.25 10.855 25.553 84.731


$PoseParameter "body_pitch" -45 45 0
$PoseParameter "body_yaw" -45 45 0

$Sequence "ref" {
	"saxton_hale_anims\ref.smd"
	fadein 0.2
	fadeout 0.2
	fps 30
}

$Sequence "ragdoll" {
	"saxton_hale_anims\ragdoll.smd"
	activity "ACT_DIERAGDOLL" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}

$IncludeModel "player/soldier_animations.mdl"

$IKChain "rhand" "bip_hand_R" knee 0 0 0
$IKChain "lhand" "bip_hand_L" knee 0 0 0
$IKChain "rfoot" "bip_foot_R" knee 0 0 0
$IKChain "lfoot" "bip_foot_L" knee 0 0 0
