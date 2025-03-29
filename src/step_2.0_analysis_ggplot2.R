library(ggplot2)
library(tidyr)
library(dplyr)
setwd("../res/")

fns <- dir(".", "results.*.txt$")
overalls <- sapply(fns, function(fn) {
  allns <- readLines(fn)
  acc <- grep("Overall", allns, value = TRUE)
  return(as.numeric(gsub("^O.*:", "", acc)))
})
overalls <- as.data.frame(overalls)
overalls <- pivot_longer(overalls, cols = seq_len(ncol(overalls))) %>% 
  separate(col = "name", into = c("network", "county"), sep = "_results_")
overalls$county <- substr(overalls$county, 1, 5)
# names(overalls)
overalls$county <- factor(overalls$county, labels = c("Livingston, IL", "McLean, IL", "Perkins, NE", "Renville, ND", "Shelby, OH", "Hale, TX"))
overalls$network <- factor(overalls$network, 
                           levels = c("dnn", "rnn_ii", "rnn_bi", "rnn_ib", "qinn", "quinn"),
                           labels = c("DNN", "RNN1", "RNN2", "RNN3", "QINN", "QINN2"))
pdf("boxplot.pdf", width = 10, height = 6)
# lattice::bwplot(value ~ factor(network) | factor(county), data = overalls, 
#        ylim = c(45, 105), ylab = "Overall accuracy")
names(overalls)[1L] <- "Models"
ggplot(data = overalls, aes(x = Models, y = value, group = Models)) +
  geom_boxplot(aes(fill=Models)) +
  facet_wrap(~ county) +
  labs(x = '', y = 'Overall Accuracy (%)') +
  ylim(c(50, 105)) + 
  theme_light() +
  theme(axis.text.x = element_text(colour="grey20", size=12, angle=90, hjust=.5, vjust=.5),
        axis.text.y = element_text(colour="grey20", size=12),
        text=element_text(size=16))
names(overalls)[1L] <- "network"
dev.off()

dtset <- overalls %>% group_by(county, network) %>% 
  summarize(accuracy = mean(value)) %>%
  pivot_wider(names_from = "network", values_from = "accuracy")
write.csv(dtset, file = "overall_means.csv", row.names = FALSE)


### Time analysis
tempi <- as.data.frame(sapply(fns, function(fn) {
  allns <- readLines(fn)
  acc <- grep("Training", allns, value = TRUE)
  return(as.numeric(gsub("^Tr.*:", "", acc)))
}))
tempi <- pivot_longer(tempi, cols = seq_len(ncol(tempi))) %>% 
  separate(col = "name", into = c("network", "county"), sep = "_results_")
tempi$county <- substr(tempi$county, 1, 5)
names(tempi)
tempi$county <- factor(tempi$county, labels = c("Livingston, IL", "McLean, IL", "Perkins, NE", "Renville, ND", "Shelby, OH", "Hale, TX"))
tempi$network <- factor(tempi$network, 
                        levels = c("dnn", "rnn_ii", "rnn_bi", "rnn_ib", "qinn", "quinn"),
                        labels = c("DNN", "RNN1", "RNN2", "RNN3", "QINN", "QINN2"))
rtmp <- tempi
pdf("time_plot.pdf", width = 10, height = 6)
# lattice::bwplot(value ~ factor(network) | factor(county), data = rtmp, 
#        ylab = "Training time (seconds)")
names(rtmp)[1L] <- "Models"
ggplot(data = rtmp, aes(x = Models, y = value, group = Models)) +
  geom_boxplot(aes(fill=Models)) +
  facet_wrap(~ county) +
  labs(x = '', y = 'Total training time (seconds)') +
  ylim(c(0, 220)) + 
  theme_light() +
  theme(axis.text.x = element_text(colour="grey20", size=12, angle=90, hjust=.5, vjust=.5),
        axis.text.y = element_text(colour="grey20", size=12),
        text=element_text(size=16))
names(rtmp)[1L] <- "network"
dev.off()

dtset <- tempi %>% group_by(county, network) %>% 
  summarize(accuracy = mean(value)) %>%
  pivot_wider(names_from = "network", values_from = "accuracy")
# dtset[, 2:4] <- dtset[, 2:4] / 4
# dtset[, 5] <- dtset[, 5] / 32
write.csv(dtset, file = "time_means.csv", row.names = FALSE)
