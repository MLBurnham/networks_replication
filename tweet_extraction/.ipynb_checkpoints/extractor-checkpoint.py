#!/usr/bin/env python
# -*- coding: utf-8 -*-

from tqdm import tqdm
import tweepy
import sys
import argparse
import time


import mmap
from secrets import consumer_key, consumer_secret, access_token, access_token_secret
from itertools import islice
import datetime

def next_n_lines(file_opened, N):
    return [int(x.strip()) for x in islice(file_opened, N)]

parser = argparse.ArgumentParser(description=
    "Simple Twitter tweet recover")
parser.add_argument('-i', '--ids', required=True, metavar="id_file",
                    help='target screen_name')

parser.add_argument('-o', '--output',required=True, help='path')
args = parser.parse_args()


def limit_handled(cursor):
    while True:
        try:
            yield cursor.next()
        except tweepy.RateLimitError:
            time.sleep(15 * 60)



def get_num_lines(file_path):
    fp = open(file_path, "r+")
    buf = mmap.mmap(fp.fileno(), 0)
    lines = 0
    while buf.readline():
        lines += 1
    return lines

def main():
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)
    twitter_api = tweepy.API(auth)

    last_wait_call = datetime.datetime.now()
    twitter_timewindow = datetime.timedelta(minutes=15)

    nb_call=0
    with open(args.output, 'w') as output:
        with open(args.ids, 'r') as input_ids:
            with tqdm(total=get_num_lines(args.ids),unit="tweets") as pbar:
                pbar.set_description("Fetching tweets")
                while True:

                    batch = next_n_lines(input_ids, 100)
                    if len(batch) == 0:
                        break

                    try:
                        nb_call += 1
                        response = twitter_api.statuses_lookup(batch)
                    except tweepy.error.RateLimitError:
                        now = datetime.datetime.now()
                        should_wait_to = last_wait_call + twitter_timewindow
                        time_to_wait = int((should_wait_to-now).total_seconds()) + 5 # I keep 5 seconds security
                        with tqdm(total=time_to_wait,unit="seconds") as pbar2:
                            pbar2.set_description("Waiting  because of twitter restriction")
                            for waited in range(time_to_wait):
                                time.sleep(1)
                                pbar2.update(1)

                        last_wait_call = now
                        response = twitter_api.statuses_lookup(batch)
                    pbar.update(len(batch))
                    output.writelines((str(resp._json)+"\n" for resp in response))


if __name__ == '__main__':

    main()
