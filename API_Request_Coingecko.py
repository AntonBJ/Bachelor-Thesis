#this python script has the gnuplot script for plotting already integrated. Please change the all-cap variables
#according to your needs

import pandas as pd
import urllib.request
import json
import datetime as dt
import time
import os
from pycoingecko import CoinGeckoAPI

cg = CoinGeckoAPI()

###Ticker/ID Liste erhalten
print("Start to get coingecko id_list")

ticker_list = pd.DataFrame({'ticker': ["BTC","ETH","BCH","BSV","LTC","XMR","ETC","DASH","ZEC","DOGE","DGB","DCR","BTG","BCD","SC","RVN","XVG","MONA","CKB","KMD","NRG","ABBC","HBZ","XZC","XHV","BEAM","PAI","NIM","GRIN","ADK","SYS","CCXX","MWC","AIB","CNX","CCA","BDX","BCN","VITAE","PLC","XNC","CSC","HNS","HNC","BON","VTC","LOKI","ILC","GRS","MOON","UNO","LBC","MBC","EMC2","DERO","QRL","ETP","POLIS","AEON","XMC","PPC","ECA","QRK","TOSC","XAS","GAME","NMC","XLQ","ZANO","LBTC","COMP","OTO","NPC","BPC","NLG","ARRR","VIA","UBQ","ZEL","XRC","XDN","BST","FLO","TUBE","BTX","HTML","FLASH","VIPS","LCC","EMC","TERA","XCP","AYA","RBTC","MINT","ECC","FTC","MIR","NSD","IXC", "GRC", "XMY", "SIN", "POT", "PEG", "BBR", "GLEEC", "XST"]})
id_list = pd.DataFrame({'id': ['btc']})

coin_list=pd.DataFrame(cg.get_coins_list())

t = 0

for y in range(0,len(ticker_list)):
    coin = (ticker_list['ticker'][y]).lower()       
    id_list.loc[t] = coin_list[coin_list['symbol']==coin]['id'].values[0]
    t = t+1

print("id_list done\n") 

###

#From date in UNIX Timestamp (eg. 1392577232)
start_date = dt.datetime(2016, 8, 1, 0, 0, 0)
end_date = dt.datetime(2020, 8, 1, 0, 0, 0)

unixtime_start = time.mktime(start_date.timetuple())
unixtime_end = time.mktime(end_date.timetuple())

print(start_date)

#print(df['prices'][1][:])   len(ticker_list)
for x in range(0,2):

    #API Request
    ticker = id_list['id'][x]
    data=cg.get_coin_market_chart_range_by_id(id=ticker,vs_currency='usd', from_timestamp=unixtime_start, to_timestamp=unixtime_end)

    print("Starting Request No {} for {}".format(x, ticker))

    print(data)
    print(len(data['prices']))
    print(len(data['total_volumes']))
    print(len(data['market_caps']))

    length = len(data['prices'])

    my_dict = dict(data)

    print(my_dict)

    df = pd.DataFrame.from_dict(my_dict, orient='index')
    df= df.transpose()

    df['timestamps'] = pd.DataFrame({'timestamps': []})
    df['p'] = pd.DataFrame({'p': []})
    df['market_cap'] = pd.DataFrame({'market_cap': []})

    print(df['prices'])

    df = df.drop(columns=['prices'][0][0])

    print(df['prices'])

    exit()


    #Clean Up
    for i in range(length):
        df['prices'][i][0] = time.strftime('%Y.%m.%d %H', time.localtime((df['prices'][i][0])/1000)) #%Y.%m.%d %H:%M:%S'
        df['timestamps'].loc[i] = df['prices'][i][0]
        df['p'].loc[i] = df['prices'][i][1]
        df['market_cap'].loc[i] = df['market_caps'][i][1]

    print(df)

    df = df.drop(columns=['prices'][0])
    df = df.drop(columns = ['market_caps'])
    df = df.drop(columns = ['total_volumes'])

    df = df.rename(columns={'p': "{}".format(ticker)})
    df = df.rename(columns={'market_cap': 'market_caps_{}'.format(ticker)})

    df.set_index('timestamps', inplace=True)

    df.to_csv(r'C:/Users/anton/OneDrive/Antons-Dokumente/Bachelor Arbeit/Nomics API/Coingecko/Data/{}.csv'.format(ticker), index = True)     

    #Combine lists
    if x == 0:
        df_combined = df
    else:
        df_combined = df.join(df_combined, how='outer')
        df_combined= pd.concat([df_combined, df], ignore_index=False)

    print(df)

    del df

#Print Final List
df_combined.to_csv(r'C:/Users/anton/OneDrive/Antons-Dokumente/Bachelor Arbeit/Nomics API/Coingecko/Data/complete_list.csv', index = True)
print(df_combined)