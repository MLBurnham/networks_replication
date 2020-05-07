load('Barbera/retweets-data.rdata')
g_retweet <- graph_from_edgelist(as.matrix(retweets[,c(2,3)]))
g_retweets <- simplify(g_retweets, )

load('retweet_fr_layout.RData')

plot.igraph(g_retweet, 
     layout = retweetfr,
     vertex.label = NA,
     vertex.size = 1.5,
     vertex.frame.color = NA,
     edge.color ='gray',
     edge.width = .25
    )