EverQuest Mission Grind Automation

This repository contains automation scripts used with MacroQuest + RGMercs to repeatedly run specific missions for experience, loot, or progression.

The scripts automate the full mission cycle:

Navigate to the quest giver

Pause RGMercs to prevent interference

Request the mission

Wait for the group to zone in

Drop a fellowship campfire

Switch the group to chase mode

Put the tank in Hunt pull mode

Begin pulling and clearing mobs

Clean up when the mission ends

These scripts are designed for multibox groups running RGMercs.

Included Scripts
The Grind

Primary mission automation script.

Automates the entire mission loop including:

requesting the mission

group positioning

campfire creation

pull automation

mission cleanup

This script establishes the standard pattern used by all other scripts.

Counterpart Scripts

The following scripts follow the same structure and logic as The Grind, but are configured for different missions.

thecall.lua

Mission automation for:

Essedera — The Call
Zone: Eastern Wastes

Handles:

mission request

ready coordination

invis break

group positioning

campfire deployment

tank hunt pulling

mission cleanup

thecrusaders.lua

Mission automation for:

Watcher Sprin — The Crusaders
Zone: Cobalt Scar

Same automation pattern as The Call, adapted for this mission.

Additional Counterpart Scripts

Additional missions may follow the same template:

navigation to NPC

synchronized ready call

campfire placement

pull automation

These scripts reuse the same logic structure so they behave consistently.

Script Behavior
Mission Request Phase

The script:

Pauses all RGMercs clients

Navigates the group to the quest giver

Targets the NPC

Requests the mission

Waits for group members to gather

Example behavior:

/rgl pauseall
/nav spawn NPC
/say small

The script then waits until all group members are within range before continuing.

Ready Synchronization

Before zoning into the mission the script ensures:

all players are within range

invisibility is removed

everyone issues the ready call

This prevents rogues or bards from remaining invisible.

Campfire Deployment

After zoning in the script:

waits until most fellowship members are nearby

opens the fellowship window

deploys a campfire

This allows group members to return to camp if they die.

Combat Phase

Once the campfire exists the script:

switches the group to chase mode

unpauses RGMercs

sets the tank to Hunt pull mode

starts pulling

Example:

/rgl set PullMode 3
/rgl setmode hunt
/rgl pullstart

PullMode values:

Mode	Value
Normal	1
Chain	2
Hunt	3
Farm	4
Death Handling

If the player dies:

chase mode is disabled

camp mode is cleared

the script waits for rez

chase mode resumes

Mission Completion

When the mission ends:

The script:

stops navigation

disables chase

clears camp

removes the fellowship campfire

kicks the group from the task

waits before restarting

This prevents the group from immediately re-triggering the mission.

Requirements

These scripts require:

MacroQuest

RGMercs

MQ2Nav

MQ2DanNet (recommended)

Fellowship Campfire

Your group should be configured so:

the tank runs pull logic

the rest of the group runs chase mode

Group Requirements

Recommended group composition:

1 tank (puller)

1 healer

4 DPS

All characters must:

be in the same fellowship

have a campfire kit available

run RGMercs

Starting the Script

Run the script from the mission request zone.

Example:

/lua run thecall

or

/lua run thecrusaders

The script will exit if started in the wrong zone.

Troubleshooting
Rogues staying invisible

The scripts force invis break before ready calls.

If this still occurs ensure the RGMercs setting:

BreakInvisForSay

is enabled.

Group not pulling

Verify the tank is switched to:

PullMode = Hunt

and that pulling is started with:

/rgl pullstart
Campfire not spawning

Check:

fellowship members nearby

campfire kit available

correct zone

Notes

These scripts are designed for repeatable mission grinding with minimal supervision.

They assume:

the tank is the puller

group members follow via chase

RGMercs handles combat rotations

Author: Cannonballdex