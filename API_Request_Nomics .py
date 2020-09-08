import pandas as pd
import urllib.request
import json
import datetime as dt
import time

#Personal Nomics Key
key = "48e9dc14c1a0042343c9f8bd0587b51a"

#List of Currencies
ticker_list = pd.DataFrame({'ticker': ["BTC","ETH","BCH","BSV","LTC","XMR","ETC","DASH","ZEC","DOGE","DGB","DCR","BTG","BCD","SC","RVN","XVG","MONA","CKB","KMD","NRG","ABBC","HBZ","XZC","XHV","BEAM","PAI","NIM","GRIN","ADK","SYS","CCXX","MWC","AIB","CNX","CCA","BDX","BCN","VITAE","PLC","XNC","CSC","HNS","HNC","BON","VTC","LOKI","ILC","GRS","MOON","UNO","LBC","MBC","EMC2","DERO","QRL","ETP","POLIS","AEON","XMC","PPC","ECA","QRK","TOSC","XAS","GAME","NMC","XLQ","ZANO","LBTC","COMP","OTO","NPC","BPC","NLG","ARRR","VIA","UBQ","ZEL","XRC","XDN","BST","FLO","TUBE","BTX","HTML","FLASH","VIPS","LCC","EMC","TERA","XCP","AYA","RBTC","MINT","ECC","FTC","MIR","NSD","IXC", "GRC", "XMY", "SIN", "POT", "PEG", "BBR", "GLEEC", "XST"]})

tl_size = ticker_list['ticker'].size

#The sparklines cutoff is: 1h intervals for up to 7 days; 1d intervals for up to 45 days
start_date = dt.datetime(2015, 8, 1)
end_date = dt.datetime(2020, 8, 1)

#Iterating through currency list
for x in range(0,tl_size):

    #API Request
    ticker = ticker_list['ticker'][x]
    print("Starting Request No {} for {}".format(x, ticker))

    request_date_start = start_date
    request_date_end = start_date + dt.timedelta(days=20)

    i = 0
    d = False

    #Get data for ticker, max 45 days per request possible
    while request_date_end < end_date:

        print(ticker, "Request No.{} from {} to {}".format(i,request_date_start,request_date_end))

        currencies_sparkline = "https://api.nomics.com/v1/currencies/sparkline?key={}&ids={}&start={}T00%3A00%3A00Z&end={}T00%3A00%3A00Z&interval=1d".format(key, ticker, request_date_start.strftime("%Y-%m-%d"), request_date_end.strftime("%Y-%m-%d"))

        #Decode Data from byte-format
        data = urllib.request.urlopen(currencies_sparkline).read()

        data = data.decode("utf-8")
        data = json.loads(data)

        #data might be empty
        if data !=[]:

            df = pd.DataFrame(data[0])

            #Clean-Up
            df = df.drop(columns=['currency'])
            df = df.rename(columns={"prices": "{}".format(ticker)})

            #TimeStamp as Index and to date-format
            df['timestamps'] = pd.to_datetime(df['timestamps']).dt.date
            df.set_index('timestamps', inplace=True)

            #merge data
            if d == False:
                df_combined = df
                d = True
            else:
                df_combined = pd.concat([df_combined,df])

        request_date_start = request_date_start + dt.timedelta(days=21)
        request_date_end = request_date_start + dt.timedelta(days=20)

        i = i+1

    print(ticker," done\n")

    try:
        if x == 0:
            df_final = df_combined
        else:
            df_final = df_final.join(df_combined, how='outer')

        df_combined.to_csv(r'C:/Users/anton/OneDrive/Antons-Dokumente/Bachelor Arbeit/Nomics API/Testing/complete_list_{}.csv'.format(ticker), index = False)     

        del df
        del df_combined

        df_final.to_csv(r'C:/Users/anton/OneDrive/Antons-Dokumente/Bachelor Arbeit/Nomics API/Testing/complete_list_final.csv', index = True)

    except NameError:
        print("No Data for ", ticker )
        pass


