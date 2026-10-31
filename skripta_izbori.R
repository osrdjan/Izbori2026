# Load necessary libraries
library(ggplot2)
library(dplyr)
library(stringr)
library(ggtext)
# library(ggthemes)

# Read the data
df <- read.csv("election_dataset.csv")

# Sort the data in descending order by num_votes_rulling
df <- df %>%
  arrange(desc(num_votes_rulling))

# Function to create formatted labels
format_label <- function(label) {
  parts <- str_split(label, ",")[[1]]
  left <- parts[1]
  right <- parts[2]
  paste0(
    "<span style='color:#003057'>",left,"</span>",
    "<span style='color:black'>,</span>",
    "<span style='color:#57004C'>",right,"</span>"
  )
}

# Apply the formatting function to the labels
df$formatted_label <- sapply(df$combined_label, format_label)

custom_colors <- c("#00429d","#1147a0","#1d4da2","#2552a5","#2c58a7","#335daa","#3963ac","#3f69af",
                   "#446eb1","#4a74b4","#4f7ab6","#547fb8","#5985bb","#5e8bbd","#6391c0","#6997c2",
                   "#6e9dc4","#73a2c6","#78a8c9","#7eaecb","#83b4cd","#89bacf","#8fc0d1","#95c6d3",
                   "#9bccd5","#a1d2d7","#a8d8d9","#afddda","#b7e3dc","#bfe9de","#c8eedf","#d1f3e0",
                   "#ddf8e1","#eafde1","#ffffe0")

# Create the plot
p <- ggplot(df, aes(x = num_votes_rulling, y = reorder(voting_area, num_votes_rulling))) +
  geom_bar(stat = "identity", fill = custom_colors) +
  coord_cartesian(xlim = c(0, 2400), expand = FALSE, clip = "off") +
  geom_richtext(aes(label = formatted_label), hjust = 0, nudge_x = -5, size = 4, fill = NA, label.color = NA) +
  scale_x_continuous(breaks = seq(0, 2350, by = 300)) +
  labs(title = "Број и проценат режимских бирача (<span style='color:#003057'>% од укупно регистрованих</span>, <span style='color:#57004C'>% од изашлих</span>)",
       x = "Број режимских бирача по подручјима Општине Ужице",
       y = NULL) +
  theme_bw() +
  theme(
    plot.title = element_markdown(size = 14, face = "bold"),
    axis.text.y = element_text(size = 12, hjust = 1,face = "bold",vjust=0.3),
    axis.text.x = element_text(size = 12, face="bold"),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    # panel.grid.major.x = element_blank(),
    # panel.grid.minor.x = element_blank(),
    plot.margin = margin(t = 5, r = 5, b = 5, l = 5),
    legend.position = "none"
  )

# Save the plot to a file
ggsave("election_plotxx1.png", plot = p, width = 10, height = 8)


# Save the plot to a file
ggsave("election_plotxx1.png", plot = p, width = 10, height = 8)

# Print the plot
p