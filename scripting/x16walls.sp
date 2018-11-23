#include <sourcemod>
#include <sdktools>
#define DMG_BULLET			(1 << 1)

//Минимальный и максимальный урон
#define MIN_DAMAGE 30
#define MAX_DAMAGE 50

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
}

public void Event_WeaponFire(Handle event, const char[] szName, bool dontBroadcast)
{
	char weapon[PLATFORM_MAX_PATH];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	OnFireBullets(GetClientOfUserId(GetEventInt(event, "userid")), 0, weapon);
}

public void OnFireBullets(iClient, iShots, const char[] szWeapon)
{
	//Защита от всего, кроме оружий!
	if (StrContains(szWeapon,"knife",false) == -1 && StrContains(szWeapon,"bayonet",false) == -1 && StrContains(szWeapon,"flashbang",false) == -1 && StrContains(szWeapon,"decoy",false) == -1 && StrContains(szWeapon,"grenade",false) == -1)
	{
		int i = GetClientViewClient(iClient);
		int x = GetClientAimTarget(iClient, true);
		if ((!IsValidClient(i)) && (IsValidClient(x)) && ((GetClientTeam(iClient)) != (GetClientTeam(x))))
		{
			int d = GetRandomInt(MIN_DAMAGE, MAX_DAMAGE); 
			DealDamage(x, d, iClient, DMG_BULLET, szWeapon);
			PrintToChatAll(" >> \x03%N\x01 --|--> \x03%N\x01 | %s",iClient,x,szWeapon);
			
			//Мы можем использовать SDKHooks_TakeDamage вместо DealDamage, но тогда не создастся события о уроне (SDKHook_OnTakeDamage)
			//Например, перестанет работать плагин, показывающий нанесённый дамаг.
			//На всякий случай я оставлю это здесь :
			//SDKHooks_TakeDamage(x, iClient, iClient, float(d), DMG_BULLET, -1, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public int GetClientViewClient(int iClient)
{
    float m_vecOrigin[3],m_angRotation[3];
    GetClientEyePosition(iClient, m_vecOrigin);
    GetClientEyeAngles(iClient, m_angRotation);
    Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_SOLID_BRUSHONLY, RayType_Infinite, TRDontHitSelf, iClient);
    int pEntity = -1;
    if (TR_DidHit(tr)) {
        pEntity = TR_GetEntityIndex(tr);
        delete tr;
        if (!IsValidClient(iClient)) return -1;
        if (!IsValidEntity(pEntity)) return -1;
        if (!IsValidClient(pEntity)) return -1;
        return pEntity;
    }
    delete tr;
    return -1;
}

stock bool TRDontHitSelf(int iEnt, int mask, any data) {
    if (iEnt == data) return false;
    return true;
}

stock bool IsValidClient(int iClient) {
    return (1 <= iClient <= MaxClients && IsClientInGame(iClient));
}

stock void DealDamage(int nClientVictim, int nDamage, int nClientAttacker = 0, int nDamageType = DMG_BULLET, const char[] sWeapon = "")
{
    // taken from: http://forums.alliedmods.net/showthread.php?t=111684
    // thanks to the authors!
    if(    nClientVictim > 0 &&
            IsValidEdict(nClientVictim) &&
            IsClientInGame(nClientVictim) &&
            IsPlayerAlive(nClientVictim) &&
            nDamage > 0)
    {
        int EntityPointHurt = CreateEntityByName("point_hurt");
        if(EntityPointHurt != 0)
        {
            char sDamage[16];
            IntToString(nDamage, sDamage, sizeof(sDamage));

            char sDamageType[32];
            IntToString(nDamageType, sDamageType, sizeof(sDamageType));
            DispatchKeyValue(nClientVictim,"targetname","hurtme");
            DispatchKeyValue(EntityPointHurt,"DamageTarget","hurtme");
            DispatchKeyValue(EntityPointHurt,"Damage",sDamage);
            DispatchKeyValue(EntityPointHurt,"DamageType",sDamageType);
            if(!StrEqual(sWeapon, "")) DispatchKeyValue(EntityPointHurt,    "classname",        sWeapon);
            DispatchSpawn(EntityPointHurt);
            AcceptEntityInput(EntityPointHurt,"Hurt", (nClientAttacker != 0) ? nClientAttacker : -1);
            DispatchKeyValue(EntityPointHurt,"classname","point_hurt");
            DispatchKeyValue(nClientVictim,"targetname","donthurtme");

            RemoveEdict(EntityPointHurt);
        }
    }
}

