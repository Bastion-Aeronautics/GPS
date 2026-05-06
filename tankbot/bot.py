import discord
import time
import random
import numpy as np

LOCOMOTION = {"tracked":    [0.4    ,0.2    ,0.2    ,0.2 ], 
              "wheeled":    [0      ,0.3    ,0.4    ,0.3 ], 
              "hovering":   [0.25   ,0.25,  0.25    ,0.25]}

TYPES = {"Tank":        [0.9    ,0.1    ,0.0    ,0.0], 
         "SPG":         [1      ,0.0    ,0.0    ,0.0], 
         "SPAA":        [0.0    ,0.2    ,0.6    ,0.2], 
         "IFV":         [0.8    ,0.1    ,0.1    ,0.0]}

TYPE_RATE = {"Tank": [0.0, 0.0, 0.0, 0.9, 0.1, 0.0], 
             "SPG":  [0.0, 0.0, 0.0, 0.75, 0.2, 0.05],
             "SPAA": [0.7, 0.2, 0.1, 0.0, 0.0, 0.0],
             "IFV":  [0.3, 0.1, 0.4, 0.2, 0.0, 0.0]}

WEAPON_COUNT = ["with a", 
                "with two", 
                "with four", 
                "with six"]

WEAPON_TYPE = ["Light Autocannon", "Rotary Autocannon", "Heavy Autocannon", "Battle Cannon", "Artillery Cannon", "Bertha Cannon"]

IMAGES = 6

global image_sent
global image_list

image_sent = 0
image_list = []

for i in range(IMAGES):
    image_list.append(f"./img/{i}.jpg")
    print(f"\033[32mINFO:\033[0m Loaded image: {image_list[-1]}")  # Debug output for loaded images

random.shuffle(image_list)  # Shuffle the list of images for randomness
print(f"\033[32mINFO:\033[0m Shuffling image list")  # Debug output for shuffled images

def idea():
    """
    Uses a weighted system to generate a random tank idea to return as a string
    """
    np.random.seed(int(time.time()*100%2147483647))  # Seed with current time for variability

    locomotion = np.random.choice(list(LOCOMOTION.keys()), p=[0.85, 0.14, 0.01])  # More likely to get tracked tanks
    next_p = LOCOMOTION[locomotion]

    type_choice = np.random.choice(list(TYPES.keys()), p=next_p)
    next_p = TYPES[type_choice]

    weapon_count = np.random.choice(WEAPON_COUNT, p=next_p)
    next_p = TYPE_RATE[type_choice]

    weapon_type = np.random.choice(WEAPON_TYPE, p=next_p)

    if weapon_count == "with a":
        s = ""
    else:
        s = "s"


    starting = np.random.choice(["Build a", "How about a", "What about a"])
    print(f"\033[32mDEBUG:\033[0m Generated '{locomotion}', '{type_choice}', '{weapon_count}', '{weapon_type}'")  # Debug output
    
    return (f"{starting} {locomotion} {type_choice} {weapon_count} {weapon_type}{s}")

start_time = time.time()

# I swear to GOD do NOT PUT THIS ON GITHUB
TOKEN = 'MTUwMTQwNjUyNjM0MDk4OTExMg.GVZKDj.J49RVD1lKeYkl_DdViLdLCNu6_kpvcEHcxn7AU'

class MyBot(discord.Client):
    def __init__(self):
        super().__init__(intents=discord.Intents.default())
        self.tree = discord.app_commands.CommandTree(self)

    async def setup_hook(self):
        await self.tree.sync() # Registers slash commands with Discord

client = MyBot()

@client.event
async def on_ready():
    print('\n')
    print(f'\033[32mINFO:\033[0m Logged in as [{client.user}] (ID: {client.user.id})')
    print('\n')

### Debug
@client.tree.command(name="ping", description="Replies with Pong!")
async def ping(interaction: discord.Interaction, ephemeral: bool = True):
    await interaction.response.send_message("Pong!", ephemeral=ephemeral)
    print(f"\033[32mCOMMAND:\033[0m Responded to ping from [{interaction.user}] (ID: {interaction.user.id})")

@client.tree.command(name="uptime", description="Replies with the bot's uptime")
async def uptime_command(interaction: discord.Interaction, ephemeral: bool = True):
    current_time = time.time()
    uptime = current_time - start_time
    await interaction.response.send_message(f"Uptime: {uptime:.0f} seconds", ephemeral=ephemeral)
    print(f"\033[32mCOMMAND:\033[0m Reported uptime to [{interaction.user}] (ID: {interaction.user.id})")

# commands
@client.tree.command(name="idea", description="Generates a random tank idea")
async def idea_command(interaction: discord.Interaction, ephemeral: bool = True):
    result = idea()
    await interaction.response.send_message(result, ephemeral=ephemeral)
    print(f"\033[32mCOMMAND:\033[0m Generated tank idea for [{interaction.user}] (ID: {interaction.user.id})")

@client.tree.command(name="feedback", description="Sends feedback directly to the developer (sav)")
async def feedback_command(interaction: discord.Interaction, feedback: str):
    await interaction.response.send_message("Feedback recieved", ephemeral=True)
    print(f"\033[32mCOMMAND:\033[0m Received feedback from [{interaction.user}] (ID: {interaction.user.id}): {feedback}")


@client.tree.command(name="send", description="Sends a message to the channel anonymously")
async def send_command(interaction: discord.Interaction, message: str):
    await interaction.response.send_message("Message sent", ephemeral=True)
    channel = interaction.channel
    await channel.send(message)
    print(f"\033[32mCOMMAND:\033[0m Sent anonymous message from [{interaction.user}] (ID: {interaction.user.id}): {message}")

@client.tree.command(name="8tank", description="Yes, No, Maybe?")
async def eightball_command(interaction: discord.Interaction, question: str, ephemeral: bool = False):
    responses = ["Yes", "No", "Maybe", "Definitely", "Absolutely not", "For sure", "Very doubtful", "I have no clue", "Maybe tomorrow", "The outlook is good", "Concentrate and ask again", "Don't count on it", "My sources say no", "Unfortunately", "Go flip a coin", "Fortunately", "Luckily", "Unluckily"]
    random.seed(time.time())
    response = random.choice(responses)
    if len(question) < 5:
        await interaction.response.send_message(f'`"{question}"`\nCan you give me a bit more detail?', ephemeral=ephemeral)
        print(f"\033[32mCOMMAND:\033[0m Received short ass question from [{interaction.user}] (ID: {interaction.user.id}): '{question}'")
    else:
        await interaction.response.send_message(f'`"{question}"`\n{response}', ephemeral=ephemeral)
        print(f"\033[32mCOMMAND:\033[0m Rolled the dice for [{interaction.user}] (ID: {interaction.user.id}): Question: '{question}' | Response: '{response}'")

@client.tree.command(name="tank", description="Sends images of tanks")
async def tank_command(interaction: discord.Interaction):
    global image_sent
    global image_list

    print(f"\033[32mCOMMAND:\033[0m Called tank command for [{interaction.user}] (ID: {interaction.user.id})")

    if image_sent < IMAGES:
        await interaction.response.defer()
        await interaction.edit_original_response(attachments=[discord.File(image_list[image_sent])])
        print(f"\033[32mINFO:\033[0m Sent picture of tank")
        image_sent += 1
    else:
        await interaction.response.send_message("Out of images, reshuffling")
        print(f"\033[33mWARN:\033[0m Out of tank images, reshuffling list")
        random.shuffle(image_list)
        image_sent = 0

client.run(TOKEN)