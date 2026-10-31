# Ulaz: election_dataset_2026_biracka_mesta.csv (prepis i provera lokalnih PDF-ova).
# Izlazi: election_dataset_2026.csv i election_plot_2026.png.
# Režimski glasovi = zbir lista 1 i 2, prema zahtevu korisnika.
# NA ne znači nula. Nepotpuna područja obeležena su zvezdicom.
# Pokretanje: Rscript skripta_izbori_2026.R [putanja_do_foldera]

needed <- c("ggplot2", "ggtext", "ragg")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Nedostaju R paketi: ", paste(missing, collapse = ", "),
                          ". Instalacija: install.packages(c('", paste(missing, collapse="','"), "'))")
suppressPackageStartupMessages(library(ggplot2))

args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
base_dir <- if (length(args)) normalizePath(args[1], mustWork = TRUE) else if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE))
} else if (length(source_files)) {
  dirname(normalizePath(tail(source_files, 1)[[1]], mustWork = TRUE))
} else getwd()

bm <- read.csv(file.path(base_dir, "election_dataset_2026_biracka_mesta.csv"),
               fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE,
               na.strings = "NA", check.names = FALSE)
vote_cols <- sprintf("votes_list_%02d", 1:18)
stopifnot(nrow(bm) == 89, !anyDuplicated(bm$unique_id), all(bm$has_results %in% c(0, 1)))
available <- bm[bm$has_results == 1, ]
stopifnot(all(rowSums(available[vote_cols]) == available$num_valid_ballots),
          all(available$num_ballots_in_box == available$num_valid_ballots + available$num_invalid_ballots),
          all(available$num_votes_rulling == available$votes_list_01 + available$votes_list_02),
          all(bm$voting_area[bm$unique_id %in% c("UZ-53", "UZ-54")] == "Пора"))

sum_present <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
format_pct <- function(x) ifelse(is.na(x), "н/д", sprintf("%.0f%%", 100 * x))
parts <- split(bm, bm$voting_area)
df <- do.call(rbind, lapply(parts, function(g) {
  a <- g[g$has_results == 1, ]
  n <- nrow(a)
  ruling <- sum_present(a$num_votes_rulling)
  other <- sum_present(a$num_votes_other_lists)
  turnout <- sum_present(a$num_voted)
  registered_complete <- n > 0 && !anyNA(a$num_registered_voters)
  registered <- if (registered_complete) sum(a$num_registered_voters) else NA_real_
  pct_reg <- ruling / registered
  pct_voted <- ruling / turnout
  # Legacy field spelling and first eight columns retained for compatibility.
  # num_votes_opposition means ALL remaining valid list votes, not a political classification.
  result <- data.frame(
    voting_area = g$voting_area[1], num_votes_rulling = ruling,
    num_votes_opposition = other, num_voted = turnout,
    num_registered_voters = registered,
    percentage_won_by_rulling_of_num_registered = pct_reg,
    percentage_won_by_rulling_of_voted = pct_voted,
    combined_label = paste(format_pct(pct_reg), format_pct(pct_voted), sep = ", "),
    num_votes_other_lists = other,
    num_valid_ballots = sum_present(a$num_valid_ballots),
    num_invalid_ballots = sum_present(a$num_invalid_ballots),
    num_ballots_in_box = sum_present(a$num_ballots_in_box),
    num_polling_stations_expected = nrow(g),
    num_polling_stations_with_results = n,
    results_complete = n == nrow(g),
    registered_voters_complete_for_available_results = registered_complete,
    num_registered_voters_known = sum_present(a$num_registered_voters),
    missing_polling_station_ids = paste(g$unique_id[g$has_results == 0], collapse = "; "),
    missing_registered_voter_ids = paste(a$unique_id[is.na(a$num_registered_voters)], collapse = "; "),
    polling_station_ids_included = paste(a$unique_id, collapse = "; "),
    election_date = "2026-10-25", ruling_lists = "1+2",
    stringsAsFactors = FALSE
  )
  for (col in vote_cols) result[[col]] <- sum_present(a[[col]])
  result
}))
rownames(df) <- NULL
df <- df[order(df$num_votes_rulling, decreasing = TRUE), ]
stopifnot(nrow(df) == 35,
          sum(df$num_votes_rulling) == sum(available$num_votes_rulling),
          sum(df$num_votes_opposition) + sum(df$num_votes_rulling) == sum(available$num_valid_ballots),
          sum(df$num_voted) == sum(available$num_voted),
          sum(df$num_polling_stations_with_results) == nrow(available))
write.csv(df, file.path(base_dir, "election_dataset_2026.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "NA")

df$area_label <- paste0(df$voting_area, ifelse(df$results_complete, "", " *"))
df$area_label <- factor(df$area_label, levels = rev(df$area_label))
df$fill <- grDevices::colorRampPalette(c("#00429d", "#547fb8", "#89bacf", "#c8eedf", "#ffffe0"))(nrow(df))
counts <- format(df$num_votes_rulling, big.mark = " ", trim = TRUE, scientific = FALSE)
df$formatted_label <- paste0(
  "<span style='color:#333333'><b>", counts, "</b></span>  ",
  "<span style='color:#003057'>", format_pct(df$percentage_won_by_rulling_of_num_registered), "</span>",
  ", <span style='color:#57004C'>", format_pct(df$percentage_won_by_rulling_of_voted), "</span>"
)
max_votes <- max(df$num_votes_rulling)
x_max <- 2700
partial <- df[!df$results_complete, ]
coverage_note <- if (nrow(partial)) paste0("* ", paste(paste0(
  partial$voting_area, ": ", partial$num_polling_stations_with_results,
  " од ", partial$num_polling_stations_expected, " БМ"), collapse = "; "),
  ". Збирови и проценти за њих обухватају само достављене резултате.") else character(0)
reg_missing <- df[is.na(df$num_registered_voters), ]
reg_note <- if (nrow(reg_missing)) paste0("н/д: недостаје број уписаних бирача за ",
  paste(paste0(reg_missing$voting_area, " (", reg_missing$missing_registered_voter_ids, ")"), collapse = "; "),
  ".") else character(0)
caption <- paste(c(coverage_note, reg_note,
  "Извор: достављени записници и исправке за БМ 75 и 80. БМ 53 и 54 сврстани су у Пору."), collapse = "\n")
p <- ggplot(df, aes(x = num_votes_rulling, y = area_label)) +
  geom_col(aes(fill = fill), width = .88) +
  scale_fill_identity() +
  ggtext::geom_richtext(aes(label = formatted_label), hjust = 0,
                       nudge_x = max_votes * .008, size = 3.7,
                       family = "Arial", fill = NA, label.color = NA,
                       label.padding = grid::unit(c(0, 0, 0, 0), "pt")) +
  scale_x_continuous(breaks = seq(0, x_max, by = 300),
                     expand = expansion(mult = c(0, 0))) +
  coord_cartesian(xlim = c(0, x_max), clip = "off") +
  labs(
    title = "Број и проценат режимских бирача",
    subtitle = paste0("Ужице и Севојно, парламентарни избори 25.10.2026. Збир листа 1 и 2.<br>",
                      "Ознаке уз траке: <b>број гласова</b>, ",
                      "<span style='color:#003057'>% од уписаних</span>, ",
                      "<span style='color:#57004C'>% од изашлих</span>"),
    x = "Број гласова за листе 1 и 2 по подручјима", y = NULL,
    caption = caption
  ) +
  theme_bw(base_family = "Arial") +
  theme(
    plot.title = element_text(size = 20, face = "bold", margin = margin(b = 6)),
    plot.subtitle = ggtext::element_markdown(size = 11.5, lineheight = 1.3, margin = margin(b = 12)),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.caption = element_text(size = 9, color = "#444444", hjust = 0,
                                lineheight = 1.25, margin = margin(t = 12)),
    axis.text.y = element_text(size = 10.8, face = "bold", hjust = 1),
    axis.text.x = element_text(size = 10.5),
    axis.title.x = element_text(size = 12, margin = margin(t = 8)),
    axis.ticks.y = element_blank(), panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(), panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_line(color = "#e7e7e7", linewidth = .35),
    panel.border = element_rect(color = "#555555", linewidth = .6),
    plot.margin = margin(15, 20, 15, 15), legend.position = "none"
  )
ggsave(file.path(base_dir, "election_plot_2026.png"), p,
       device = ragg::agg_png, width = 14, height = 11.5, dpi = 300, bg = "white")
message("Gotovo: ", nrow(df), " podrucja, ", nrow(available), "/", nrow(bm), " BM, ", sum(df$num_votes_rulling), " glasova za liste 1+2.")
print(df[, c("voting_area", "num_votes_rulling", "combined_label", "results_complete")], row.names = FALSE)
if (interactive()) print(p)
