# Poređenje postojećih brojeva iz dataset-a za 2024. i 2026.
# Polje num_votes_rulling koristi se kako je dato u svakom ulaznom skupu.
# Izlazi: election_comparison_2024_2026.csv i election_comparison_2024_2026.png.
# Pokretanje: Rscript skripta_poredjenje_2024_2026.R [putanja_do_foldera]

needed <- c("ggplot2", "ggtext", "ragg")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Nedostaju R paketi: ", paste(missing, collapse = ", "))
suppressPackageStartupMessages(library(ggplot2))

args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
base_dir <- if (length(args)) normalizePath(args[1], mustWork = TRUE) else if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE))
} else if (length(source_files)) {
  dirname(normalizePath(tail(source_files, 1)[[1]], mustWork = TRUE))
} else getwd()

old <- read.csv(file.path(base_dir, "election_dataset.csv"), fileEncoding = "UTF-8-BOM",
                stringsAsFactors = FALSE, check.names = FALSE)
new <- read.csv(file.path(base_dir, "election_dataset_2026.csv"), fileEncoding = "UTF-8-BOM",
                stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(!anyDuplicated(old$voting_area), !anyDuplicated(new$voting_area),
          setequal(old$voting_area, new$voting_area), nrow(old) == 35,
          all(new$results_complete))
joined <- merge(old, new, by = "voting_area", suffixes = c("_2024", "_2026"), sort = FALSE)
valid_2024 <- joined$num_votes_rulling_2024 + joined$num_votes_opposition_2024
valid_2026 <- joined$num_valid_ballots
stopifnot(all(valid_2024 > 0), all(valid_2026 > 0),
          all(joined$num_registered_voters_2024 > 0), all(joined$num_registered_voters_2026 > 0),
          all(joined$num_votes_rulling_2024 <= valid_2024),
          all(joined$num_votes_rulling_2026 <= valid_2026))

comparison <- data.frame(
  voting_area = joined$voting_area,
  num_votes_rulling_2024 = joined$num_votes_rulling_2024,
  num_votes_rulling_2026 = joined$num_votes_rulling_2026,
  change_votes = joined$num_votes_rulling_2026 - joined$num_votes_rulling_2024,
  change_votes_pct = 100 * (joined$num_votes_rulling_2026 / joined$num_votes_rulling_2024 - 1),
  num_registered_voters_2024 = joined$num_registered_voters_2024,
  num_registered_voters_2026 = joined$num_registered_voters_2026,
  change_registered_voters = joined$num_registered_voters_2026 - joined$num_registered_voters_2024,
  num_valid_ballots_2024 = valid_2024,
  num_valid_ballots_2026 = valid_2026,
  change_valid_ballots = valid_2026 - valid_2024,
  share_registered_2024 = joined$num_votes_rulling_2024 / joined$num_registered_voters_2024,
  share_registered_2026 = joined$num_votes_rulling_2026 / joined$num_registered_voters_2026,
  share_valid_2024 = joined$num_votes_rulling_2024 / valid_2024,
  share_valid_2026 = joined$num_votes_rulling_2026 / valid_2026,
  num_votes_other_lists_2024 = joined$num_votes_opposition_2024,
  num_votes_other_lists_2026 = joined$num_votes_other_lists,
  num_voted_source_2024 = joined$num_voted_2024,
  num_voted_source_2026 = joined$num_voted_2026,
  stringsAsFactors = FALSE
)
comparison$change_share_registered_pp <- 100 * (comparison$share_registered_2026 - comparison$share_registered_2024)
comparison$change_share_valid_pp <- 100 * (comparison$share_valid_2026 - comparison$share_valid_2024)
comparison <- comparison[order(-comparison$change_share_registered_pp, comparison$voting_area), ]
rownames(comparison) <- NULL
stopifnot(!anyNA(comparison),
          sum(comparison$change_votes) == sum(new$num_votes_rulling) - sum(old$num_votes_rulling),
          sum(comparison$num_valid_ballots_2024) == sum(old$num_votes_rulling + old$num_votes_opposition),
          sum(comparison$num_valid_ballots_2026) == sum(new$num_valid_ballots))
write.csv(comparison, file.path(base_dir, "election_comparison_2024_2026.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "NA")

metric_names <- c("Промена броја гласова\nгласови", "Промена удела међу уписанима\nпроцентни поени",
                  "Промена удела у важећим гласовима\nпроцентни поени")
plot_data <- do.call(rbind, lapply(seq_along(metric_names), function(i) {
  values <- comparison[[c("change_votes", "change_share_registered_pp", "change_share_valid_pp")[i]]]
  data.frame(voting_area = comparison$voting_area, metric = metric_names[i], value = values,
             label = if (i == 1) sprintf("%+d", values) else chartr(".", ",", sprintf("%+.1f", values)),
             stringsAsFactors = FALSE)
}))
plot_data$label[plot_data$value == 0] <- "0"
plot_data$metric <- factor(plot_data$metric, levels = metric_names)
plot_data$voting_area <- factor(plot_data$voting_area, levels = rev(comparison$voting_area))
plot_data$direction <- ifelse(plot_data$value > 0, "Раст", ifelse(plot_data$value < 0, "Пад", "Без промене"))
plot_data$hjust <- ifelse(plot_data$value >= 0, 0, 1)
plot_data$label_x <- plot_data$value
for (metric in metric_names) {
  idx <- plot_data$metric == metric
  span <- diff(range(c(0, plot_data$value[idx])))
  plot_data$label_x[idx] <- plot_data$value[idx] + ifelse(plot_data$value[idx] >= 0, 1, -1) * span * .018
}

# Leave room for labels outside the bars. Each panel has its own numeric scale.
bounds <- do.call(rbind, lapply(metric_names, function(metric) {
  values <- plot_data$value[plot_data$metric == metric]
  low <- min(0, values); high <- max(0, values); width <- high - low
  data.frame(metric = metric, value = c(low - width * .25, high + width * .25),
             voting_area = comparison$voting_area[1])
}))
bounds$metric <- factor(bounds$metric, levels = metric_names)
bounds$voting_area <- factor(bounds$voting_area, levels = levels(plot_data$voting_area))
positive <- "#2868A8"
negative <- "#C76732"

overall_votes <- sum(comparison$num_votes_rulling_2026) - sum(comparison$num_votes_rulling_2024)
overall_reg_pp <- 100 * (sum(comparison$num_votes_rulling_2026) / sum(comparison$num_registered_voters_2026) -
                         sum(comparison$num_votes_rulling_2024) / sum(comparison$num_registered_voters_2024))
overall_valid_pp <- 100 * (sum(comparison$num_votes_rulling_2026) / sum(comparison$num_valid_ballots_2026) -
                           sum(comparison$num_votes_rulling_2024) / sum(comparison$num_valid_ballots_2024))
signed <- function(x) chartr(".", ",", sprintf("%+.2f", x))
headline <- paste0("Укупно: <b>+", format(overall_votes, big.mark = " ", trim = TRUE), " гласова</b>; ",
                   "<b>", signed(overall_reg_pp), " п.п.</b> међу уписанима; ",
                   "<b>", signed(overall_valid_pp), " п.п.</b> у важећим гласовима.")

p <- ggplot(plot_data, aes(x = value, y = voting_area)) +
  geom_blank(data = bounds) +
  geom_vline(xintercept = 0, color = "#444B54", linewidth = .55) +
  geom_col(aes(fill = direction), width = .73) +
  geom_point(data = plot_data[plot_data$value == 0, ], color = "#6B7280", size = 2) +
  geom_text(aes(x = label_x, label = label, hjust = hjust, color = direction), size = 3.4, family = "Arial") +
  facet_wrap(~ metric, nrow = 1, scales = "free_x") +
  scale_fill_manual(values = c("Раст" = positive, "Пад" = negative, "Без промене" = "#6B7280")) +
  scale_color_manual(values = c("Раст" = positive, "Пад" = negative, "Без промене" = "#6B7280")) +
  scale_x_continuous(breaks = function(limits) pretty(limits, n = 5), expand = expansion(mult = 0)) +
  scale_y_discrete(limits = rev(comparison$voting_area), expand = expansion(add = .7)) +
  labs(
    title = "Промене режимских гласова по подручјима, 2024–2026.",
    subtitle = paste0("Разлике су рачунате као 2026. минус 2024. ",
                      "<span style='color:", positive, "'><b>Плаво: раст.</b></span> ",
                      "<span style='color:", negative, "'><b>Наранџасто: пад.</b></span><br>", headline),
    x = NULL, y = NULL,
    caption = "Удели су рачунати из постојећих бројева у достављеним скуповима. Трећи панел користи важеће гласове у обе године."
  ) +
  theme_minimal(base_family = "Arial", base_size = 11) +
  theme(
    plot.title = element_text(size = 21, face = "bold", margin = margin(b = 8)),
    plot.subtitle = ggtext::element_markdown(size = 12, lineheight = 1.35, margin = margin(b = 16)),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.caption = element_text(size = 9.5, hjust = 0, color = "#59616C", margin = margin(t = 16)),
    axis.text.y = element_text(size = 10.5, face = "bold", color = "#3E4855"),
    axis.text.x = element_text(size = 10, color = "#626B77", margin = margin(t = 6)),
    panel.grid.major.y = element_line(color = "#EEF0F3", linewidth = .3),
    panel.grid.major.x = element_line(color = "#E5E8EE", linewidth = .35),
    panel.grid.minor = element_blank(), panel.spacing.x = grid::unit(1.3, "lines"),
    strip.text = element_text(size = 11.4, face = "bold", lineheight = 1.2, color = "#283342", margin = margin(b = 13)),
    legend.position = "none", plot.margin = margin(18, 25, 18, 18)
  )
ggsave(file.path(base_dir, "election_comparison_2024_2026.png"), p,
       device = ragg::agg_png, width = 17, height = 12.2, dpi = 300, bg = "white")
message("Gotovo: poređenje 35 područja. Ukupna promena glasova: ", overall_votes,
        "; medju upisanima: ", signed(overall_reg_pp), " pp; u vazecim: ", signed(overall_valid_pp), " pp.")
if (interactive()) print(p)
