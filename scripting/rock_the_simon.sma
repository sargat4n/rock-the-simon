#include <amxmodx>
#include <cstrike>

#define PLUGIN_NAME "Rock the Simon"
#define PLUGIN_VERSION "0.2.0"
#define PLUGIN_AUTHOR "Sargatan (https://steamcommunity.com/id/sargatan)"

#define VOTE_TIME 10.0

new bool:g_tCalled[33];
new bool:g_voteInProgress;
new bool:g_roundUsed;
new g_matchUsed;
new g_rtsCooldown;
new g_cvarRtsCooldownRounds;
new g_voteCounts[33];
new g_voteMenu;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    // Cvar principal del mod
    register_cvar("rts_enabled", "1");
    register_cvar("rts_per_match", "1");
    g_cvarRtsCooldownRounds = register_cvar("rts_cooldown_rounds", "3");

    register_clcmd("rts", "cmd_rts");
    register_clcmd("rockthesimon", "cmd_rts");

    register_clcmd("say rts", "cmd_rts");
    register_clcmd("say /rts", "cmd_rts");
    register_clcmd("say rockthesimon", "cmd_rts");
    register_clcmd("say /rockthesimon", "cmd_rts");

    register_logevent("on_round_start", 2, "1=Round_Start");
}

public on_round_start()
{
    reset_round_state();

    if (g_rtsCooldown > 0)
    {
        g_rtsCooldown--;
    }
}

public cmd_rts(id)
{
    if (!is_user_connected(id))
    {
        return PLUGIN_HANDLED;
    }

    if (get_cvar_num("rts_enabled") == 0)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] El plugin está deshabilitado.");
        return PLUGIN_HANDLED;
    }

    if (g_voteInProgress || g_roundUsed)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] La votación ya está en curso o ya se usó esta ronda.");
        return PLUGIN_HANDLED;
    }

    if (g_rtsCooldown > 0)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] Faltan %d rondas para poder usar RTS nuevamente.", g_rtsCooldown);
        return PLUGIN_HANDLED;
    }

    new perMatch = get_cvar_num("rts_per_match");
    if (perMatch > 0 && g_matchUsed >= perMatch)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] Ya se alcanzó el límite de RTS en esta partida.");
        return PLUGIN_HANDLED;
    }

    if (perMatch > 0)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] RTS disponibles en la partida: %d.", perMatch - g_matchUsed);
    }
    else
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] RTS disponibles en la partida: ilimitados.");
    }

    if (has_admins_connected())
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] El RTS solo se habilita cuando no hay administradores conectados.");
        return PLUGIN_HANDLED;
    }

    if (cs_get_user_team(id) != CS_TEAM_T)
    {
        rts_print_color(id, CS_TEAM_T, "[RTS] Solo los ^3prisioneros^1 pueden usar este comando.");
        return PLUGIN_HANDLED;
    }

    if (get_ct_count() < 1)
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] Debe haber al menos 1 ^3guardia^1 para iniciar la votación.");
        return PLUGIN_HANDLED;
    }

    if (!is_rts_ratio_allowed())
    {
        rts_print_color(id, CS_TEAM_CT, "[RTS] El RTS solo se habilita cuando hay más ^3guardias^1 que 1 por cada 4 ^3prisioneros^1.");
        return PLUGIN_HANDLED;
    }

    if (!g_tCalled[id])
    {
        g_tCalled[id] = true;
        rts_print_color(id, CS_TEAM_CT, "[RTS] Tu voto para iniciar fue registrado.");

        new name[32];
        get_user_name(id, name, charsmax(name));

        new total = get_tt_count();
        new called = count_t_called();
        new remaining = total - called;
        if (remaining < 0)
        {
            remaining = 0;
        }

        rts_print_color(0, CS_TEAM_CT, "[RTS] %s solicitó un RTS, faltan %d para iniciar una votación para transferir un ^3guardia^1.", name, remaining);
    }

    if (all_terrorists_called())
    {
        start_vote();
    }

    return PLUGIN_HANDLED;
}

stock reset_round_state()
{
    g_voteInProgress = false;
    g_roundUsed = false;
    g_voteMenu = 0;

    for (new i = 1; i <= 32; i++)
    {
        g_tCalled[i] = false;
        g_voteCounts[i] = 0;
    }

    remove_task(12345);
}

stock bool:has_admins_connected()
{
    new players[32], num;
    get_players(players, num, "ch");

    for (new i = 0; i < num; i++)
    {
        new id = players[i];
        if (get_user_flags(id) & ADMIN_KICK)
        {
            return true;
        }
    }

    return false;
}

stock bool:all_terrorists_called()
{
    new players[32], num;
    get_players(players, num, "ae", "TERRORIST");

    if (num < 1)
    {
        return false;
    }

    for (new i = 0; i < num; i++)
    {
        if (!g_tCalled[players[i]])
        {
            return false;
        }
    }

    return true;
}

stock get_tt_count()
{
    new players[32], num;
    get_players(players, num, "ae", "TERRORIST");
    return num;
}

stock count_t_called()
{
    new players[32], num;
    get_players(players, num, "ae", "TERRORIST");

    new count = 0;
    for (new i = 0; i < num; i++)
    {
        if (g_tCalled[players[i]])
        {
            count++;
        }
    }

    return count;
}

stock get_ct_count()
{
    new players[32], num;
    get_players(players, num, "e", "CT");
    return num;
}

stock bool:is_rts_ratio_allowed()
{
    new tcount = get_tt_count();
    new ctcount = get_ct_count();

    if (tcount < 1)
    {
        return false;
    }

    new maxCt = (tcount + 3) / 4;
    return ctcount > maxCt;
}

stock start_vote()
{
    g_voteInProgress = true;
    g_roundUsed = true;
    g_matchUsed++;
    g_rtsCooldown = get_pcvar_num(g_cvarRtsCooldownRounds);

    for (new i = 1; i <= 32; i++)
    {
        g_voteCounts[i] = 0;
        g_tCalled[i] = false;
    }

    g_voteMenu = menu_create("Rock the Simon - Elegí un guardia/simón", "vote_handler");

    new players[32], num;
    get_players(players, num, "ae", "CT");

    for (new i = 0; i < num; i++)
    {
        new id = players[i];
        new name[32];
        new data[6];

        get_user_name(id, name, charsmax(name));
        num_to_str(id, data, charsmax(data));
        menu_additem(g_voteMenu, name, data);
    }

    rts_print_color(0, CS_TEAM_CT, "[RTS] Se inició la votación: elijan un ^3guardia^1 / ^3simón^1.");

    new tplayers[32], tnum;
    get_players(tplayers, tnum, "ae", "TERRORIST");
    for (new i = 0; i < tnum; i++)
    {
        menu_display(tplayers[i], g_voteMenu, 0);
    }

    set_task(VOTE_TIME, "finish_vote", 12345);
}

public vote_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        return PLUGIN_HANDLED;
    }

    new data[6], name[64], access, callback;
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);

    new target = str_to_num(data);
    if (is_user_connected(target))
    {
        g_voteCounts[target]++;

        new tname[32];
        get_user_name(target, tname, charsmax(tname));
        rts_print_color(id, CS_TEAM_T, "[RTS] Seleccionaste a %s para ser transferido al equipo de ^3prisioneros^1.", tname);
    }

    return PLUGIN_HANDLED;
}

public finish_vote()
{
    if (!g_voteInProgress)
    {
        return;
    }

    g_voteInProgress = false;

    if (g_voteMenu)
    {
        menu_destroy(g_voteMenu);
        g_voteMenu = 0;
    }

    new players[32], num;
    get_players(players, num, "ae", "CT");

    if (num < 1)
    {
        rts_print_color(0, CS_TEAM_CT, "[RTS] No hay ^3guardias^1 disponibles para cambiar de equipo.");
        return;
    }

    new tplayers[32], tnum;
    get_players(tplayers, tnum, "ae", "TERRORIST");

    if (tnum < 1)
    {
        rts_print_color(0, CS_TEAM_T, "[RTS] No hay ^3prisioneros^1 disponibles para votar.");
        return;
    }

    new winner = players[0];
    new bestVotes = g_voteCounts[winner];

    for (new i = 1; i < num; i++)
    {
        new id = players[i];
        if (g_voteCounts[id] > bestVotes)
        {
            bestVotes = g_voteCounts[id];
            winner = id;
        }
    }

    new topname[32];
    get_user_name(winner, topname, charsmax(topname));
    rts_print_color(0, CS_TEAM_CT, "[RTS] El ^3guardia^1 / ^3simón^1 con más votos fue %s.", topname);

    new requiredVotes = (tnum * 80 + 99) / 100;

    if (bestVotes < requiredVotes)
    {
        new wname[32];
        get_user_name(winner, wname, charsmax(wname));
        rts_print_color(0, CS_TEAM_CT, "[RTS] No se alcanzó el 80%% de consenso para cambiar al ^3guardia^1 ^4%s^1.", wname);
        return;
    }

    if (is_user_connected(winner))
    {
        new name[32];
        get_user_name(winner, name, charsmax(name));
        cs_set_user_team(winner, CS_TEAM_T);
    }
}

stock rts_print_color(id, CsTeams:team, const fmt[], any:...)
{
    new message[191];
    vformat(message, charsmax(message), fmt, 4);

    ensure_color_prefix(message);

    new sender = 0;
    new CsTeams:desiredTeam = get_desired_team(message, team);

    sender = get_sender_by_team(desiredTeam);
    if (sender == 0 && id > 0 && is_user_connected(id))
    {
        sender = id;
    }

    if (sender == 0)
    {
        sender = get_any_player();
        if (sender == 0)
        {
            strip_color_codes(message);
            client_print(id, print_chat, "%s", message);
            return;
        }
    }

    client_print_color(id, sender, "%s", message);
}

stock CsTeams:get_desired_team(const msg[], CsTeams:defaultTeam)
{
    if (containi(msg, "prisioneros") != -1 || containi(msg, "prisionero") != -1)
    {
        return CS_TEAM_T;
    }

    if (containi(msg, "guardia") != -1 || containi(msg, "guardias") != -1 || containi(msg, "simón") != -1 || containi(msg, "simon") != -1)
    {
        return CS_TEAM_CT;
    }

    return defaultTeam;
}

stock ensure_color_prefix(msg[])
{
    if (msg[0] == 94)
    {
        return;
    }

    new temp[191];
    formatex(temp, charsmax(temp), "^1%s", msg);
    copy(msg, charsmax(temp), temp);
}

stock get_any_player()
{
    new players[32], num;
    get_players(players, num, "h");

    if (num > 0)
    {
        return players[0];
    }

    return 0;
}

stock get_sender_by_team(CsTeams:team)
{
    new players[32], num;

    if (team == CS_TEAM_CT)
    {
        get_players(players, num, "e", "CT");
    }
    else if (team == CS_TEAM_T)
    {
        get_players(players, num, "e", "TERRORIST");
    }

    if (num > 0)
    {
        return players[0];
    }

    return 0;
}

stock strip_color_codes(msg[])
{
    new len = strlen(msg);
    new output[191];
    new j = 0;

    for (new i = 0; i < len && j < charsmax(output); i++)
    {
        if (msg[i] == 94 && msg[i + 1] >= '0' && msg[i + 1] <= '9')
        {
            i++;
            continue;
        }

        output[j++] = msg[i];
    }

    output[j] = 0;
    copy(msg, charsmax(output), output);
}
