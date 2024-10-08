#' Customisable ggplot2 ordination plot
#'
#' Draw ordination plot. Utilises psExtra object produced by of \code{\link{ord_calc}}.
#' - For an extensive tutorial see \href{https://david-barnett.github.io/microViz/articles/web-only/ordination.html}{the ordination vignette}.
#' - For interpretation see the the relevant pages on PCA, PCoA, RDA, or CCA on the GUide to STatistical Analysis in Microbial Ecology (GUSTA ME) website: \url{https://sites.google.com/site/mb3gustame/}
#'
#' How to specify the plot_taxa argument (when using PCA, CCA or RDA):
#' - FALSE --> plot no taxa vectors or labels
#' - integer vector e.g. 1:3 --> plot labels for top 3 taxa (by longest line length)
#' - single numeric value e.g. 0.75 --> plot labels for taxa with line length > 0.75
#' - character vector e.g. c('g__Bacteroides', 'g__Veillonella') --> plot labels for the exactly named taxa
#'
#' @param data
#' psExtra object with ordination attached, i.e. output from ord_calc
#' @param axes
#'  which axes to plot: numerical vector of length 2, e.g. 1:2 or c(3,5)
#' @param plot_taxa
#' if ord_calc method was "PCA/RDA" draw the taxa loading vectors (see details)
#' @param tax_vec_length taxon arrow vector scale multiplier.
#' NA = auto-scaling, or provide a numeric multiplier yourself.
#' @param tax_vec_style_all
#' list of named aesthetic attributes for all (background) taxon vectors
#' @param tax_vec_style_sel
#' list of named aesthetic attributes for taxon vectors for the taxa selected by plot_taxa
#' @param tax_lab_length
#' scale multiplier for label distance/position for any selected taxa
#' @param tax_lab_style
#' list of style options for the taxon labels, see tax_lab_style() function.
#' @param taxon_renamer
#' function that takes any plotted taxon names and returns modified names for labels
#' @param plot_samples
#' if TRUE, plot sample points with geom_point
#' @param constraint_vec_length
#' constraint arrow vector scale multiplier.
#' NA = auto-scaling, or provide a numeric multiplier yourself.
#' @param constraint_vec_style
#' list of aesthetics/arguments (colour, alpha etc) for the constraint vectors
#' @param constraint_lab_length label distance/position for any constraints
#' (relative to default position which is proportional to correlations with each axis)
#' @param constraint_lab_style
#' list of aesthetics/arguments (colour, size etc) for the constraint labels
#' @param var_renamer
#' function to rename constraining variables for plotting their labels
#' @param scaling
#' Type 2, or type 1 scaling. For more info,
#' see \url{https://sites.google.com/site/mb3gustame/constrained-analyses/redundancy-analysis}.
#' Either "species" or "site" scores are scaled by (proportional) eigenvalues,
#' and the other set of scores is left unscaled (from ?vegan::scores.cca)
#' @param auto_caption
#' size of caption with info about the ordination, NA for none
#' @param center expand plot limits to center around origin point (0,0)
#' @param clip clipping of labels that extend outside plot limits?
#' @param expand expand plot limits a little bit further than data range?
#' @param interactive
#' creates plot suitable for use with ggiraph (used in ord_explore)
#' @param ...
#' pass aesthetics arguments for sample points,
#' drawn with geom_point using aes_string
#'
#' @return ggplot
#' @export
#' @seealso \code{\link{tax_lab_style}} / \code{\link{tax_lab_style}} for styling labels
#' @seealso \code{\link{ord_explore}} for interactive ordination plots
#' @seealso \code{\link{ord_calc}} for calculating an ordination to plot with ord_plot
#'
#' @examples
#' library(ggplot2)
#' data("dietswap", package = "microbiome")
#'
#' # create a couple of numerical variables to use as constraints or conditions
#' dietswap <- dietswap %>%
#'   ps_mutate(
#'     weight = dplyr::recode(bmi_group, obese = 3, overweight = 2, lean = 1),
#'     female = dplyr::if_else(sex == "female", true = 1, false = 0)
#'   )
#'
#' # unconstrained PCA ordination
#' unconstrained_aitchison_pca <- dietswap %>%
#'   tax_transform("clr", rank = "Genus") %>%
#'   ord_calc() # method = "auto" --> picks PCA as no constraints or distances
#'
#' unconstrained_aitchison_pca %>%
#'   ord_plot(colour = "bmi_group", plot_taxa = 1:5) +
#'   stat_ellipse(aes(linetype = bmi_group, colour = bmi_group))
#'
#' # you can generate an interactive version of the plot by specifying
#' # interactive = TRUE, and passing a variable name to another argument
#' # called `data_id` which is required for interactive point selection
#' interactive_plot <- unconstrained_aitchison_pca %>%
#'   ord_plot(
#'     colour = "bmi_group", plot_taxa = 1:5,
#'     interactive = TRUE, data_id = "sample"
#'   )
#'
#' # to start the html viewer, and allow selecting points, we must use a
#' # ggiraph function called girafe and set some options and css
#' ggiraph::girafe(
#'   ggobj = interactive_plot,
#'   options = list(
#'     ggiraph::opts_selection(
#'       css = ggiraph::girafe_css(
#'         css = "fill:orange;stroke:black;",
#'         point = "stroke-width:1.5px"
#'       ),
#'       type = "multiple", # this activates lasso selection (click top-right)
#'       only_shiny = FALSE # allows interactive plot outside of shiny app
#'     )
#'   )
#' )
#'
#'
#' # remove effect of weight with conditions arg
#' # scaling weight with scale_cc is not necessary as only 1 condition is used
#' dietswap %>%
#'   tax_transform("clr", rank = "Genus") %>%
#'   ord_calc(conditions = "weight", scale_cc = FALSE) %>%
#'   ord_plot(colour = "bmi_group") +
#'   stat_ellipse(aes(linetype = bmi_group, colour = bmi_group))
#'
#' # alternatively, constrain variation on weight and female
#' constrained_aitchison_rda <- dietswap %>%
#'   tax_transform("clr", rank = "Genus") %>%
#'   ord_calc(constraints = c("weight", "female")) # constraints --> RDA
#'
#' constrained_aitchison_rda %>%
#'   ord_plot(colour = "bmi_group", constraint_vec_length = 2) +
#'   stat_ellipse(aes(linetype = bmi_group, colour = bmi_group))
#'
#' # ggplot allows additional customisation of the resulting plot
#' p <- constrained_aitchison_rda %>%
#'   ord_plot(colour = "bmi_group", plot_taxa = 1:3) +
#'   lims(x = c(-5, 6), y = c(-5, 5)) +
#'   scale_colour_brewer(palette = "Set1")
#'
#' p + stat_ellipse(aes(linetype = bmi_group, colour = bmi_group))
#' p + stat_density2d(aes(colour = bmi_group))
#'
#' # you can rename the taxa on the labels with any function that
#' # takes and modifies a character vector
#' constrained_aitchison_rda %>%
#'   ord_plot(
#'     colour = "bmi_group",
#'     plot_taxa = 1:3,
#'     taxon_renamer = function(x) stringr::str_extract(x, "^.")
#'   ) +
#'   lims(x = c(-5, 6), y = c(-5, 5)) +
#'   scale_colour_brewer(palette = "Set1")
#'
#' # You can plot PCoA and constrained PCoA plots too.
#' # You don't typically need/want to use transformed taxa variables for PCoA
#' # But it is good practice to call tax_transform("identity") so that
#' # the automatic caption can record that no transformation was applied
#' dietswap %>%
#'   tax_agg("Genus") %>%
#'   tax_transform("identity") %>%
#'   # so caption can record (lack of) transform
#'   dist_calc("bray") %>%
#'   # bray curtis
#'   ord_calc() %>%
#'   # guesses you want an unconstrained PCoA
#'   ord_plot(colour = "bmi_group")
#'
#' # it is possible to facet these plots
#' # (although I'm not sure it makes sense to)
#' # but only unconstrained ordination plots and with plot_taxa = FALSE
#' unconstrained_aitchison_pca %>%
#'   ord_plot(color = "sex", auto_caption = NA) +
#'   facet_wrap("sex") +
#'   theme(line = element_blank()) +
#'   stat_density2d(aes(colour = sex)) +
#'   guides(colour = "none")
#'
#' unconstrained_aitchison_pca %>%
#'   ord_plot(color = "bmi_group", plot_samples = FALSE, auto_caption = NA) +
#'   facet_wrap("sex") +
#'   theme(line = element_blank(), axis.text = element_blank()) +
#'   stat_density2d_filled(show.legend = FALSE) +
#'   geom_point(size = 1, shape = 21, colour = "black", fill = "white")
ord_plot3d <-
  function(data,
           axes = 1:3,
           plot_taxa = FALSE,
           tax_vec_length = NA,
           tax_vec_style_all = vec_tax_all(),
           tax_vec_style_sel = vec_tax_sel(),
           tax_lab_length = tax_vec_length * 1.1,
           tax_lab_style = list(),
           taxon_renamer = function(x) identity(x),
           constraint_vec_length = NA,
           constraint_vec_style = vec_constraint(),
           constraint_lab_length = constraint_vec_length * 1.1,
           constraint_lab_style = list(),
           var_renamer = function(x) identity(x),
           plot_samples = TRUE,
           scaling = 2, # or "species" scaling in vegan lingo
           auto_caption = 8,
           center = FALSE,
           clip = "off",
           expand = !center,
           interactive = FALSE,
           ...) {
    check_is_psExtra(data, argName = "data")

    ps <- ps_get(data)
    ordination <- ord_get(data)
    # check ordination and phyloseq size (should never fail if ord_calc used)
    stopifnot(stats::nobs(ordination) == phyloseq::nsamples(ps))

    # check input data object class and extract the most used objects to function env
    if (identical(ordination, NULL)) stop("data must be psExtra output of ord_calc")
    info <- info_get(data)
    ordInfo <- info[["ord_info"]]
    isConstrained <- length(ordInfo$constraints) > 0

    # return named list of arguments matching either phyloseq variable names or
    # numbers/colors/ggplot2_shapes (throws error if any are invalid)
    ellipses <- checkValidEllipsesOrdPlot(..., ps = ps)

    # get and transform aesthetic metadata ------------------------------------
    meta <- samdatAsDataframe(ps)

    # set variable and fixed ggplot aesthetics based on metadata names check
    aestheticArgs <- ellipses[ellipses %in% colnames(meta)]
    fixed_aesthetics <- ellipses[!ellipses %in% colnames(meta)]

    # set colour variables to factors, if they're not null or numeric-like
    if (!is.null(aestheticArgs$colour)) {
      if (inherits(meta[[aestheticArgs$colour]], c("numeric", "difftime"))) {
        meta[[aestheticArgs$colour]] <- as.numeric(meta[[aestheticArgs$colour]])
      } else {
        meta[[aestheticArgs$colour]] <- as.factor(meta[[aestheticArgs$colour]])
      }
    }
    # and coerce shape variable to factor if it is a non-fixed variable
    if (!is.null(aestheticArgs$shape)) {
      meta[[aestheticArgs$shape]] <- as.factor(meta[[aestheticArgs$shape]])
    }

    # get data point positions ------------------------------------------------

    # NMDS and DCA ordinations needs alternative handling
    if (inherits(ordination, c("decorana", "metaMDS"))) {
      siteScoresDf <- as.data.frame(
        vegan::scores(ordination, display = "sites", choices = axes)
      )
      axesLabs <- axesNames <- colnames(siteScoresDf)
    } else {
      # compute summary of ordination object to ensure
      # consistent scaling of components
      ordsum <- summary(ordination, scaling = scaling, axes = max(axes))

      # retrieve scores from model object
      siteScoresDf <- as.data.frame(ordsum[["sites"]][, axes, drop = FALSE])

      # if RDA/PCA method: get species scores (aka feature loadings)
      if (info$ord_info$method %in% c("RDA", "PCA", "CCA")) {
        speciesScoresDf <- as.data.frame(ordsum[["species"]][, axes, drop = FALSE])
      }

      # if constrained model: get constraints coordinates for plotting
      if (isConstrained) {
        constraintDf <- as.data.frame(ordsum[["biplot"]][, axes, drop = FALSE])
      }

      # extract "explained variation" for labelling axes
      eigVals <- vegan::eigenvals(ordination)
      explainedVar <- eigVals[axes] / sum(eigVals)
      axesNames <- colnames(siteScoresDf)
      axesLabs <- paste0(axesNames, " [", sprintf("%.1f", 100 * explainedVar), "%]")
    }
    # bind ordination axes vectors to metadata subset for plotting
    df <- dplyr::bind_cols(siteScoresDf, meta)


    # build ggplot ------------------------------------------------------------
    ## samples ----------------------------------------------------------------
    p <- ggplot2::ggplot(data = df, mapping = ggplot2::aes(
      x = .data[[axesNames[1]]], y = .data[[axesNames[2]]], z = .data[[axesNames[3]]]
    )) +
      ggplot2::theme_minimal() +
      ggplot2::labs(x = axesLabs[1], y = axesLabs[2], z = axesLabs[3])
      ggplot2::coord_cartesian(clip = clip, default = TRUE, expand = expand)

    # set geom_point variable aesthetics
    aesthetics <- buildAesFromListOfStrings(aestheticArgs)

    # gather all args for use in geom_point (sample data)
    geompointArgs <- c(list(mapping = aesthetics), fixed_aesthetics)

    # add sample/site points, sized dynamically or fixed size
    if (plot_samples) {
      if (isTRUE(interactive)) {
        p <- p + do.call(ggiraph::geom_point_interactive, args = geompointArgs)
      } else {
        p <- p + do.call(ggplot2::geom_point, args = geompointArgs)
      }
    }

    ## taxa -------------------------------------------------------------------
    # add loadings/ species-scores arrows for RDA/PCA methods
    if (ordInfo[["method"]] %in% c("RDA", "CCA", "PCA")) {
      # return subselection of taxa for which to draw labels on plot
      selectSpeciesScoresDf <- subsetTaxaDfLabel(
        speciesScoresDf = speciesScoresDf, plot_taxa = plot_taxa
      )

      # if a selection of species scores (for labelling) was calculated,
      # add taxa lines and labels to plot
      if (!identical(selectSpeciesScoresDf, NULL)) {
        # automatic taxa vector length setting
        if (identical(tax_vec_length, NA)) {
          tax_vec_length <- computeAutoVecLength(
            vecDf = speciesScoresDf, pointsDf = siteScoresDf, prop = 0.85
          )
        }

        # (semi-transparent) lines for all taxa
        p <- ord_arrows(
          p = p, data = speciesScoresDf * tax_vec_length,
          axesNames = axesNames, styleList = tax_vec_style_all,
          defaultStyles = vec_tax_all()
        )

        # (opaque) lines for selected taxa
        p <- ord_arrows(
          p = p, data = selectSpeciesScoresDf * tax_vec_length,
          axesNames = axesNames, styleList = tax_vec_style_sel,
          defaultStyles = vec_tax_sel()
        )

        # add taxa labels
        p <- ord_labels(
          p = p, data = selectSpeciesScoresDf * tax_lab_length,
          axesNames = axesNames, renamer = taxon_renamer,
          styleList = tax_lab_style, defaultStyles = tax_lab_style()
        )
      }
    }

    ## constraints -----------------------------------------------------------
    # if constrained ordination, plot constraints
    if (isConstrained) {
      # automatic constraint length setting
      if (identical(constraint_vec_length, NA)) {
        constraint_vec_length <- computeAutoVecLength(
          vecDf = constraintDf, pointsDf = siteScoresDf, prop = 0.45
        )
      }

      # draw vector segments at length set by constraint_vec_length argument
      # (proportion of original length)
      p <- ord_arrows(
        p = p, data = constraintDf * constraint_vec_length,
        axesNames = axesNames, styleList = constraint_vec_style,
        defaultStyles = vec_constraint()
      )

      # draw vector tip labels at length set by constraint_lab_length argument
      p <- ord_labels(
        p = p, data = constraintDf * constraint_lab_length,
        axesNames = axesNames, renamer = var_renamer,
        styleList = constraint_lab_style,
        defaultStyles = constraint_lab_style()
      )
    }

    ## caption and center ----------------------------------------------------
    # add automated caption if requested (default size = 8)
    p <- ord_caption(
      p = p, ps = ps, cap_size = auto_caption, info = info, scaling = scaling
    )

    # center the plot if requested using helper function
    if (isTRUE(center)) p <- center_plot(p, clip = clip, expand = expand)

    return(p)
  }

# helper functions ------------------------------------------------------------

# https://stackoverflow.com/a/74424353/9005116
buildAesFromListOfStrings <- function(args) {
  args <- lapply(X = args, FUN = function(x) {
    if (rlang::is_string(x)) rlang::data_sym(x) else x
  })
  return(do.call(what = ggplot2::aes, args = args))
}

#' Add caption text to ordination ggplot
#'
#' @param p ggplot
#' @param ps phyloseq object to assess dimensions
#' @param cap_size caption font size (or NA for no caption addition)
#' @param info psExtraInfo list containing most info for caption
#' @param scaling type of scaling used
#'
#' @return ggplot
#' @noRd
ord_caption <- function(p, ps, cap_size, info, scaling) {
  if (identical(NA, cap_size)) {
    return(p) # return unchanged
  } else {
    o <- info$ord_info$method

    # some ordinations should have scaling type reported, when not the default
    if (o %in% c("PCA", "RDA", "CCA", "CAP") && scaling != 2) {
      o <- paste0(o, " (scaling=", scaling, ")")
    }
    if (length(info$ord_info$constraints) > 0) {
      o <- paste0(o, " constraints=", info$ord_info$constraints)
    }
    if (length(info$ord_info$conditions) > 0) {
      o <- paste0(o, " conditions=", info$ord_info$conditions)
    }

    # caption gets n taxa and samples info
    caption <- paste0(
      nrow(p[["data"]]), " samples & ", phyloseq::ntaxa(ps),
      " taxa (", info$tax_agg, "). ", o
    )

    # any transformations and distances should be listed
    if (length(info$tax_trans) > 0) {
      caption <- paste0(caption, " tax_transform=", info$tax_trans)
    }
    if (length(info$dist_method) > 0) {
      caption <- paste0(caption, " dist=", info$dist_method)
    }

    # add the caption
    p <- p + ggplot2::labs(caption = caption) +
      ggplot2::theme(plot.caption = ggplot2::element_text(size = cap_size))

    return(p)
  }
}

## centering plot ------------------------------------------------------------
center_plot <- function(plot, clip = "off", expand = TRUE) {
  lims <- get_plot_limits(plot)
  plot + ggplot2::coord_cartesian(
    xlim = c(-max(abs(lims$x)), max(abs(lims$x))),
    ylim = c(-max(abs(lims$y)), max(abs(lims$y))),
    default = TRUE, clip = clip, expand = expand
  )
}

get_plot_limits <- function(plot) {
  gb <- ggplot2::ggplot_build(plot)
  list(
    x = c(
      min = gb$layout$panel_params[[1]]$x.range[1],
      max = gb$layout$panel_params[[1]]$x.range[2]
    ),
    y = c(
      min = gb$layout$panel_params[[1]]$y.range[1],
      max = gb$layout$panel_params[[1]]$y.range[2]
    )
  )
}

## arrow length helpers ------------------------------------------------------

# rescale maximum length of vectors to be a proportion of maximum distance of
# points from origin
computeAutoVecLength <- function(vecDf, pointsDf, prop = 0.85) {
  x <- max(rowVecNorms(pointsDf)) / max(rowVecNorms(vecDf))
  tax_vec_length <- x * prop
  return(tax_vec_length)
}

# calculate lengths of 2D vectors from rows of dataframe
rowVecNorms <- function(df, cols = 1:2) {
  x <- apply(X = df[, cols, drop = FALSE], MARGIN = 1, FUN = vecNormEuclid)
  return(x)
}

# finds the euclidean norm (length) of the vector given
# useful for adjusting the length of loading/constraint arrows
# (when given x value and y value in vec)
vecNormEuclid <- function(vec) norm(vec, type = "2")

## other helpers -------------------------------------------------------------

# Takes dataframe with rownames as taxa names, and data columns are ordination
# dimensions, the first two being the ones to be plotted.
# Returns subset of that dataframe with only taxa that will be labelled,
# subset returned depends on the plot_taxa argument, which is user supplied.
subsetTaxaDfLabel <- function(speciesScoresDf, plot_taxa) {
  # calculate initial line length for taxa vectors
  speciesLineLength <- rowVecNorms(df = speciesScoresDf, cols = 1:2)

  # return subselection of taxa for which to draw labels on plot
  selectSpeciesScoresDf <- switch(
    EXPR = class(plot_taxa[[1]]),
    # default plot_taxa == TRUE --> line length > 1
    "logical" = {
      if (isTRUE(plot_taxa)) {
        speciesScoresDf[speciesLineLength > 1, , drop = FALSE]
      } else {
        NULL
      }
    },
    # integer e.g. 1:3 --> plot labels for top 3 taxa (by line length)
    "integer" = {
      speciesScoresDf[rev(order(speciesLineLength)), ][plot_taxa, , drop = FALSE]
    },
    # numeric e.g. 0.75 --> plot labels for taxa with line length > 0.75
    "numeric" = {
      speciesScoresDf[speciesLineLength > plot_taxa[[1]], , drop = FALSE]
    },
    # character e.g. c('g__Bacteroides', 'g__Veillonella')
    # --> plot labels for exactly named taxa
    "character" = {
      speciesScoresDf[rownames(speciesScoresDf) %in% plot_taxa, , drop = FALSE]
    }
  )

  return(selectSpeciesScoresDf)
}

## helpers check aesthetic args ----------------------------------------------

# return named list of arguments matching either phyloseq variable names or
# numbers/colors/ggplot2_shapes (throws error if any are invalid)
checkValidEllipsesOrdPlot <- function(..., ps) {
  # get ellipses optional arguments (aesthetics for geom_point)
  ellipses <- list(...)
  # properly delete any ellipses arguments set to NULL
  if (length(ellipses) > 0) ellipses[sapply(ellipses, is.null)] <- NULL

  # check there are STILL ellipses args left after removing nulls
  if (length(ellipses) > 0) {
    # check aesthetics colour, shape, size and alpha are all in dataset (or numeric-esque)
    variables <- phyloseq::sample_variables(ps)
    for (v in ellipses) {
      if (
        !is.null(v) && !inherits(v, c("logical", "numeric", "integer")) &&
          !(v %in% c(variables, grDevices::colors(), ggplot2_shapes()))
      ) {
        stop(v, " is not a variable in the sample metadata (or color / shape)")
      }
    }
  }
  return(ellipses)
}

# generates vector of ggplot2 shapes
ggplot2_shapes <- function() {
  c(
    "circle", paste("circle", c("open", "filled", "cross", "plus", "small")),
    "bullet",
    "square", paste("square", c("open", "filled", "cross", "plus", "triangle")),
    "diamond", paste("diamond", c("open", "filled", "plus")),
    "triangle", paste("triangle", c("open", "filled", "square")),
    paste("triangle down", c("open", "filled")),
    "plus", "cross", "asterisk"
  )
}


#mm -- added these extra functions from online
ps_extra_arg_deprecation_warning <- function(ps_extra) {
rlang::warn(call = rlang::caller_env(1), message = c(
  "ps_extra argument deprecated",
  i = "use psExtra argument instead"
))
return(ps_extra)
}

check_is_phyloseq <- function(x, argName = NULL, allow_psExtra = TRUE) {
  stopif_ps_extra(x, argName = argName, Ncallers = 2)
  isPhyloseq <- is(x, "phyloseq") && (allow_psExtra || !is(x, "psExtra"))
  
  if (!isPhyloseq) {
    CLASSES <- if (allow_psExtra) '"phyloseq" or "psExtra"' else '"phyloseq"'
    
    rlang::abort(call = rlang::caller_env(), message = c(
      paste("argument", argName, "must be a", CLASSES, "object"),
      i = paste0("argument is class: ", paste(class(x), collapse = " "))
    ))
  }
}

check_is_psExtra <- function(x, argName = NULL) {
  stopif_ps_extra(x, argName = argName, Ncallers = 2)
  if (!is(x, "psExtra")) {
    rlang::abort(call = rlang::caller_env(), message = c(
      paste("argument", argName, 'must be a "psExtra" object'),
      i = paste0("argument is class: ", paste(class(x), collapse = " "))
    ))
  }
}

#' @name psExtra-accessors
#' @title Extract elements from psExtra class
#'
#' @description
#' - `ps_get`         returns phyloseq
#' - `info_get`       returns psExtraInfo object
#' - `dist_get`       returns distance matrix (or NULL)
#' - `ord_get`        returns ordination object (or NULL)
#' - `perm_get`       returns adonis2() permanova model (or NULL)
#' - `bdisp_get`      returns results of betadisper() (or NULL)
#' - `otu_get`        returns phyloseq otu_table matrix with taxa as columns
#' - `tt_get`         returns phyloseq tax_table
#' - `tax_models_get` returns list generated by tax_model or NULL
#' - `tax_stats_get`  returns dataframe generated by tax_models2stats or NULL
#' - `taxatree_models_get` returns list generated by taxatree_models or NULL
#' - `taxatree_stats_get` returns dataframe generated by taxatree_models2stats or NULL
#' - `samdat_tbl`     returns phyloseq sample_data as a tibble
#' with sample_names as new first column called .sample_name
#'
#' @param psExtra psExtra S4 class object
#' @param ps_extra deprecated! don't use this
#'
#' @return element(s) from psExtra object (or NULL)
#' @export
#'
#' @examples
#' data("dietswap", package = "microbiome")
#'
#' psx <- tax_transform(dietswap, "compositional", rank = "Genus")
#'
#' psx
#'
#' ps_get(psx)
#'
#' ps_get(psx, counts = TRUE)
#'
#' info_get(psx)
#'
#' dist_get(psx) # this psExtra has no dist_calc result
#'
#' ord_get(psx) # this psExtra has no ord_calc result
#'
#' perm_get(psx) # this psExtra has no dist_permanova result
#'
#' bdisp_get(psx) # this psExtra has no dist_bdisp result
#'
#' # these can be returned from phyloseq objects too
#' otu_get(psx, taxa = 6:9, samples = c("Sample-9", "Sample-1", "Sample-6"))
#'
#' otu_get(psx, taxa = 6:9, samples = c(9, 1, 6), counts = TRUE)
#'
#' tt_get(psx) %>% head()
#'
#' samdat_tbl(psx)
#'
#' samdat_tbl(psx, sample_names_col = "SAMPLENAME")
#' @export
#' @rdname psExtra-accessors
ps_get <- function(psExtra, ps_extra, counts = FALSE, warn = TRUE) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_phyloseq(psExtra)
  if (isTRUE(counts)) {
    return(ps_counts(psExtra, warn = warn))
  }
  return(as(psExtra, "phyloseq"))
}
#' @rdname psExtra-accessors
#' @export
dist_get <- function(psExtra, ps_extra) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_psExtra(psExtra)
  psExtra@dist
}
#' @rdname psExtra-accessors
#' @export
ord_get <- function(psExtra, ps_extra) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_psExtra(psExtra)
  psExtra@ord
}
#' @rdname psExtra-accessors
#' @export
info_get <- function(psExtra, ps_extra) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_phyloseq(psExtra)
  if (!methods::is(psExtra, "psExtra")) {
    return(new_psExtraInfo())
  }
  return(psExtra@info)
}
#' @rdname psExtra-accessors
#' @export
perm_get <- function(psExtra, ps_extra) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_psExtra(psExtra)
  return(psExtra@permanova)
}
#' @rdname psExtra-accessors
#' @export
bdisp_get <- function(psExtra, ps_extra) {
  if (!missing(ps_extra)) psExtra <- ps_extra_arg_deprecation_warning(ps_extra)
  check_is_psExtra(psExtra)
  return(psExtra@bdisp)
}


#' @rdname psExtra-accessors
#' @export
tax_models_get <- function(psExtra) {
  check_is_psExtra(psExtra, argName = "psExtra")
  return(psExtra@tax_models)
}

#' @rdname psExtra-accessors
#' @export
tax_stats_get <- function(psExtra) {
  check_is_psExtra(psExtra, argName = "psExtra")
  return(psExtra@tax_stats)
}

#' @rdname psExtra-accessors
#' @export
taxatree_models_get <- function(psExtra) {
  check_is_psExtra(psExtra, argName = "psExtra")
  return(psExtra@taxatree_models)
}

#' @rdname psExtra-accessors
#' @export
taxatree_stats_get <- function(psExtra) {
  check_is_psExtra(psExtra, argName = "psExtra")
  return(psExtra@taxatree_stats)
}

#' @param data phyloseq or ps_extra
# @return phyloseq otu_table matrix with taxa as columns
#'
#' @param taxa subset of taxa to return, NA for all (default)
#' @param samples subset of samples to return, NA for all (default)
#' @param counts should ps_get or otu_get attempt to return counts? if present in object
#' @param warn
#' if counts = TRUE, should a warning be emitted if counts are not available?
#' set warn = "error" to stop if counts are not available
#'
#' @rdname psExtra-accessors
#' @export
otu_get <- function(data, taxa = NA, samples = NA, counts = FALSE, warn = TRUE) {
  # get otu_table from object
  if (methods::is(data, "otu_table")) {
    if (isTRUE(counts)) warning("data is otu_table: ignoring `counts = TRUE`")
    otu <- data
  } else {
    ps <- if (isTRUE(counts)) ps_counts(data, warn = warn) else ps_get(data)
    otu <- phyloseq::otu_table(ps)
  }
  if (phyloseq::taxa_are_rows(otu)) otu <- phyloseq::t(otu)
  
  # subset samples and/or taxa if requested, with slightly more helpful errors
  if (!identical(taxa, NA)) {
    stopifnot(is.character(taxa) || is.numeric(taxa) || is.logical(taxa))
    tmp <- try(expr = otu <- otu[, taxa, drop = FALSE], silent = TRUE)
    if (inherits(tmp, "try-error")) {
      if (is.character(taxa)) {
        wrong <- paste(setdiff(taxa, colnames(otu)), collapse = " / ")
        stop("The following taxa were not found in the otu table:\n", wrong)
      } else {
        stop("Invalid taxa selection")
      }
    }
  }
  if (!identical(samples, NA)) {
    stopifnot(is.character(samples) || is.numeric(samples) || is.logical(samples))
    tmp <- try(expr = otu <- otu[samples, , drop = FALSE], silent = TRUE)
    if (inherits(tmp, "try-error")) {
      if (is.character(samples)) {
        wrong <- paste(setdiff(samples, rownames(otu)), collapse = " / ")
        stop("The following samples were not found in the otu table:\n", wrong)
      } else {
        stop("Invalid sample selection")
      }
    }
  }
  return(otu)
}

#' @rdname psExtra-accessors
#' @export
tt_get <- function(data) {
  if (methods::is(data, "taxonomyTable")) {
    return(data)
  }
  tt <- phyloseq::tax_table(ps_get(data))
  return(tt)
}

#' @param data phyloseq or psExtra
# @return phyloseq sample_data as a tibble,
# with sample_names as new first column called .sample_name
#' @param sample_names_col
#' name of column where sample_names are put.
#' if NA, return data.frame with rownames (sample_names)
#' @rdname psExtra-accessors
#' @export
samdat_tbl <- function(data, sample_names_col = ".sample_name") {
  if (is(data, "sample_data") || is(data, "phyloseq")) {
    df <- samdatAsDataframe(data) # also works for psExtra
  } else {
    rlang::abort(message = c(
      "data must be of class 'phyloseq', 'psExtra', or 'sample_data'",
      i = paste("It is class:", paste(class(data), collapse = " "))
    ))
  }
  if (identical(sample_names_col, NA)) {
    return(df)
  } else {
    df <- tibble::rownames_to_column(df, var = sample_names_col)
    return(tibble::as_tibble(df, .name_repair = "check_unique"))
  }
}

#' Internal helper that gets phyloseq sample_data as a plain dataframe
#'
#' @param ps A phyloseq object.
#'
#' @return A dataframe with sample data from the phyloseq object.
#' @keywords internal
samdatAsDataframe <- function(ps) {
  samdat <- phyloseq::sample_data(ps)
  df <- data.frame(samdat, check.names = FALSE, stringsAsFactors = FALSE)
  return(df)
}

#' Get phyloseq with counts if available
#'
#' @param data A phyloseq or psExtra object.
#' @param warn
#' A boolean or "error" string to control warning or error behaviour (default: TRUE).
#'
#' @return A phyloseq object with counts if available.
#' @keywords internal
ps_counts <- function(data, warn = TRUE) {
  check_is_phyloseq(data)
  if (!rlang::is_bool(warn) && !rlang::is_string(warn, string = "error")) {
    stop("warn argument must be TRUE, FALSE, or 'error'")
  }
  # always get ps, regardless of psExtra or phyloseq data or counts presence
  ps <- ps_get(data)
  
  # get counts and use them if they exist,
  # and check regardless if otutab returned will be counts
  counts <- if (is(data, "psExtra")) data@counts else NULL
  
  # maintain existing taxa_are_rows status for consistency
  if (phyloseq::taxa_are_rows(ps) && !is.null(counts)) counts <- phyloseq::t(counts)
  
  # put non-null counts table in otu table slot
  if (!is.null(counts)) phyloseq::otu_table(ps) <- counts
  
  # check ps otu_table is counts (first checking for NAs)
  if (!isFALSE(warn)) check_otutable_is_counts(otu_get(ps), warn = warn)
  
  return(ps)
}

#' Internal helper for ps_counts
#'
#' @param otu A phyloseq otu_table object.
#' @param warn A boolean or "error" string to control warning or error behavior.
#'
#' @keywords internal
check_otutable_is_counts <- function(otu, warn) {
  # extract plain matrix from otu table
  mat <- unclass(otu)
  
  # specify warning or error
  mess_fun <- function(mess) {} # intentionally does nothing
  if (identical(warn, "error")) mess_fun <- rlang::abort
  if (isTRUE(warn)) mess_fun <- rlang::warn
  
  # check for NAs
  if (anyNA(mat)) {
    n <- sum(is.na(mat))
    mess <- paste("otu_table contains", n, "NAs")
    mess_fun(mess)
    # stops here if mess_fun is abort
    # otherwise, remove NAs for further testing
    mat <- as.numeric(mat)
    mat <- mat[!is.na(mat)]
  }
  
  # check for counts
  if (any(mat != trunc(mat)) || any(mat < 0)) {
    bad <- which(mat != trunc(mat) | mat < 0)
    mess_fun(c("otu_table of counts is NOT available!\n", paste0(
      "Available otu_table contains ", length(bad),
      " values that are not non-negative integers"
    )))
  }
}