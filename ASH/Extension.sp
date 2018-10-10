public void Ext_CheckAlivePlayers(any data) {
  if (UTIL_GetAlivePlayers(OtherTeam) == 1 && Hale > 0 && IsPlayerAlive(Hale)) {
    int iPlayer = UTIL_LookupClient(OtherTeam, TFClass_Soldier, true);
    // PrintToChatAll("UTIL_LookupClient(): Result %d", iPlayer);
    if (iPlayer > 0 && GetIndexOfWeaponSlot(iPlayer, TFWeaponSlot_Melee) == 128) {
      DataPack hPack;
      UTIL_AddFunction(ASHEvent_RoundEnd, Ext_EqualizerSpecialEnd, hPack);
      hPack.WriteCell(GetClientUserId(iPlayer));
      hPack.WriteCell(Ext_EqualizerSpecialStart(iPlayer));

      SetHudTextParams(-1.0, -1.0, 5.0, 255, 255, 255, 255);
      ShowHudText(iPlayer, -1, "%t", "ash_equalizer_special");
      ShowHudText(Hale, -1, "%t", "ash_equalizer_special");
    }
  }
}

public void Ext_EqualizerSpecialEnd(DataPack hPack) {
  int iClient = GetClientOfUserId(hPack.ReadCell());
  if (iClient == 0)
    return;

  // TF2Attrib_RemoveByDefIndex(Hale, 62);
  // TF2Attrib_SetByDefIndex(Hale, 252, 0.0);    // "damage force reduction"
  TF2Attrib_RemoveByDefIndex(iClient, hPack.ReadCell());
}

int Ext_EqualizerSpecialStart(int iClient) {
//  float flPercentage = (float(HaleHealth) / float(HaleHealthMax));
  
  float flHaleDamageNeed = (float(HaleHealthMax) / 2.5);
  if (flHaleDamageNeed >= 2500)
  {
    flHaleDamageNeed = 2500.0;
  }
  int iHaleDamageNeed = RoundToCeil(flHaleDamageNeed);
  
 // SetHudTextParams(-1.0, 0.68, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
//  ShowSyncHudText(iClient, soulsHUD, "%t: %i/%i", "ash_soldier_equalizer_meter", Damage[iClient], flHaleDamageNeed);

  if (Damage[iClient] >= iHaleDamageNeed) {
    TF2Attrib_SetByDefIndex(iClient, 26, 225.0);
    SetEntProp(iClient, Prop_Send, "m_iHealth", 425);
    HaleHealth = RoundToCeil(float(HaleHealth) * 0.5);
    // HaleHealth *= 0.5;
    return 26;
  }
  else  {
    TF2Attrib_SetByDefIndex(iClient, 125, -75.0);
    SetEntProp(iClient, Prop_Send, "m_iHealth", 125);
    return 125;
  }
}