import aiohttp
import discord
from discord.ext import commands

import os

discord_key = os.getenv('DISCORD_KEY')

intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix='!', intents=intents)

@bot.event
async def on_ready():
    print(f'{bot.user.name} successfully logged in')

@bot.command()
async def request(ctx, *, message):
    webhook_url = "http://noche-n8n.duckdns.org:5678/webhook-test/c1079c7f-5a73-4e3f-b469-131bc6dcdc80"

    data = {
        "content": message
    }

    async with aiohttp.ClientSession() as session:
        async with session.post(webhook_url, json=data) as response:
            if response.status == 200:
                result = await response.text()
                shortened_message = result[:1900]
                await ctx.send(f'{shortened_message}')
            else:
                await ctx.send(f'Error {response.status}')

bot.run(discord_key)