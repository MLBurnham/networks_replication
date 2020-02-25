# Gaumont et al Replication

This is a partial replication of the article: Gaumont N, Panahi M, Chavalarias D (2018) Reconstruction of the socio-semantic dynamics of political activist Twitter networks— Method and application to the 2017 French presidential election. PLoS ONE 13(9): e0201879. https://doi.org/10.1371/journal.pone.0201879

Specifically it focuses on the political realignment of twitter users throughout the 2017 French presidential election.

## dataverse_files
Contains original replication data files

## realignment_replication
Contains scripts and data for replicating the realignment portion of the analysis
- realignment.ipynb contains the R scripts for tagging, summarizing, and visualizing the data.
- a4_nodes.csv and a5_nodes.csv contain node lists tagged with communities identified by the Louvain algorithm. a4 is initial state data and a5 is post realignment.
- .RData files are layouts for plotting the network

## tweet_extraction
Contains a script for extracting tweets from the twitter API given a list of tweet IDs