#' VPC plotting function
#'
#' This function performs no parsing of data, it just plots the already calculated statistics generated using one of the 
#' `vpc` functions.
#' 
#' @param db object created using the `vpc` function
#' @param show what to show in VPC (obs_dv, obs_ci, pi, pi_as_area, pi_ci, obs_median, sim_median, sim_median_ci)
#' @param vpc_theme theme to be used in VPC. Expects list of class vpc_theme created with function vpc_theme()
#' @param smooth "smooth" the VPC (connect bin midpoints) or show bins as rectangular boxes. Default is TRUE.
#' @param log_x Boolean indicting whether x-axis should be shown as logarithmic. Default is FALSE.
#' @param log_y Boolean indicting whether y-axis should be shown as logarithmic. Default is FALSE.
#' @param title title
#' @param xlab ylab as numeric vector of size 2
#' @param ylab ylab as numeric vector of size 2
#' @param verbose verbosity (T/F)
#' @export
#' @seealso \link{sim_data}, \link{vpc_cens}, \link{vpc_tte}, \link{vpc_cat}
#' @examples 
#' ## See vpc.ronkeizer.com for more documentation and examples
#' 
#' library(vpc)
#' vpc_db <- vpc(sim = simple_data$sim, obs = simple_data$obs, vpcdb = TRUE)
#' plot_vpc(vpc_db, title = "My new vpc", x = "Custom x label")
plot_vpc <- function(db,
                     show = NULL,
                     vpc_theme = NULL,
                     smooth = TRUE,
                     log_x = FALSE,
                     log_y = FALSE,
                     title = NULL,
                     xlab = "Time",
                     ylab = NULL,
                     verbose = FALSE) {
  if(is.null(vpc_theme) || (class(vpc_theme) != "vpc_theme")) {
    vpc_theme <- new_vpc_theme()
  }
  idv_as_factor <- is.factor(db$vpc_dat$bin)
  if(db$type != "time-to-event") {
    show <- replace_list_elements(show_default, show)
    if(!is.null(db$stratify)) {
      ## rename "strat" to original stratification variable names
      if(length(db$stratify) == 1) {
        if(!is.null(db$aggr_obs)) colnames(db$aggr_obs)[match("strat", colnames(db$aggr_obs))] <- db$stratify[1]
        if(!is.null(db$vpc_dat)) colnames(db$vpc_dat)[match("strat", colnames(db$vpc_dat))] <- db$stratify[1]
      }
      if(length(db$stratify) == 2) {
        if(!is.null(db$aggr_obs)) {
          colnames(db$aggr_obs)[match("strat1", colnames(db$aggr_obs))] <- db$stratify[1]
          colnames(db$aggr_obs)[match("strat2", colnames(db$aggr_obs))] <- db$stratify[2]
        }
        if(!is.null(db$vpc_dat)) {
          colnames(db$vpc_dat)[match("strat1", colnames(db$vpc_dat))] <- db$stratify[1]
          colnames(db$vpc_dat)[match("strat2", colnames(db$vpc_dat))] <- db$stratify[2]
        }
      }
    }

    ################################################################
    ## VPC for continous, censored or categorical
    ## note: for now, tte-vpc is separated off, but need to unify
    ##       this with generic plotting.
    ################################################################

    if (!is.null(db$sim)) {
      if(idv_as_factor) db$vpc_dat$bin_mid <- db$vpc_dat$bin
      pl <- ggplot2::ggplot(db$vpc_dat, ggplot2::aes(x=bin_mid, group=1))
      if(show$sim_median) {
        pl <- pl + ggplot2::geom_line(ggplot2::aes(y=q50.med), colour=vpc_theme$sim_median_color, linetype=vpc_theme$sim_median_linetype, size=vpc_theme$sim_median_size)
      }
      if(show$pi_as_area) {
        if (smooth) {
          pl <- pl +
            ggplot2::geom_ribbon(ggplot2::aes(x=bin_mid, y=q50.med, ymin=q5.med, ymax=q95.med), alpha=vpc_theme$sim_median_alpha, fill = vpc_theme$sim_median_fill)
        } else {
          pl <- pl +
            ggplot2::geom_rect(ggplot2::aes(xmin=bin_min, xmax=bin_max, y=q50.med, ymin=q5.med, ymax=q95.med), alpha=vpc_theme$sim_median_alpha, fill = vpc_theme$sim_median_fill)
        }
      } else {
        if(show$sim_median_ci) {
          if (smooth) {
            pl <- pl +
              ggplot2::geom_ribbon(ggplot2::aes(x=bin_mid, y=q50.med, ymin=q50.low, ymax=q50.up), alpha=vpc_theme$sim_median_alpha, fill = vpc_theme$sim_median_fill)
          } else {
            pl <- pl +
              ggplot2::geom_rect(ggplot2::aes(xmin=bin_min, xmax=bin_max, y=q50.low, ymin=q50.low, ymax=q50.up), alpha=vpc_theme$sim_median_alpha, fill = vpc_theme$sim_median_fill)
          }
        }
        if (show$pi) {
          pl <- pl +
            ggplot2::geom_line(ggplot2::aes(x=bin_mid, y=q5.med), colour=vpc_theme$sim_pi_color, linetype=vpc_theme$sim_pi_linetype, size=vpc_theme$sim_pi_size) +
            ggplot2::geom_line(ggplot2::aes(x=bin_mid, y=q95.med), colour=vpc_theme$sim_pi_color, linetype=vpc_theme$sim_pi_linetype, size=vpc_theme$sim_pi_size)
        }
        if(show$pi_ci && !is.null(db$vpc_dat$q5.low)) {
          if (smooth) {
            pl <- pl +
              ggplot2::geom_ribbon(ggplot2::aes(x=bin_mid, y=q5.low, ymin=q5.low, ymax=q5.up), alpha=vpc_theme$sim_pi_alpha, fill = vpc_theme$sim_pi_fill) +
              ggplot2::geom_ribbon(ggplot2::aes(x=bin_mid, y=q95.low, ymin=q95.low, ymax=q95.up), alpha=vpc_theme$sim_pi_alpha, fill = vpc_theme$sim_pi_fill)
          } else {
            pl <- pl +
              ggplot2::geom_rect(ggplot2::aes(xmin=bin_min, xmax=bin_max, y=q5.low, ymin=q5.low, ymax=q5.up), alpha=vpc_theme$sim_pi_alpha, fill = vpc_theme$sim_pi_fill) +
              ggplot2::geom_rect(ggplot2::aes(xmin=bin_min, xmax=bin_max, y=q95.low, ymin=q95.low, ymax=q95.up), alpha=vpc_theme$sim_pi_alpha, fill = vpc_theme$sim_pi_fill)
          }
        }
      }
    } else {
      pl <- ggplot2::ggplot(db$aggr_obs)
    }
    if(!is.null(db$obs)) {
      if(idv_as_factor) db$aggr_obs$bin_mid <- db$aggr_obs$bin
      if (show$obs_median) {
        pl <- pl +
          ggplot2::geom_line(data=db$aggr_obs, ggplot2::aes(x=bin_mid, y=obs50), 
                             linetype=vpc_theme$obs_median_linetype, 
                             colour=vpc_theme$obs_median_color, 
                             size=vpc_theme$obs_median_size)
      }
      if(show$obs_ci && !is.null(db$aggr_obs[["obs5"]])) {
        pl <- pl +
          ggplot2::geom_line(data=db$aggr_obs, ggplot2::aes(x=bin_mid, y=obs5), linetype=vpc_theme$obs_ci_linetype, colour=vpc_theme$obs_ci_color, size=vpc_theme$obs_ci_size) +
          ggplot2::geom_line(data=db$aggr_obs, ggplot2::aes(x=bin_mid, y=obs95), linetype=vpc_theme$obs_ci_linetype, colour=vpc_theme$obs_ci_color, size=vpc_theme$obs_ci_size)
      }
      if(show$obs_dv) {
        pl <- pl + ggplot2::geom_point(data=db$obs, ggplot2::aes(x=idv, y = dv), size=vpc_theme$obs_size, colour=vpc_theme$obs_color, alpha = vpc_theme$obs_alpha, shape = vpc_theme$obs_shape)
      }
    }
    bdat <- data.frame(cbind(x=db$bins, y=NA))
    if(show$bin_sep && !idv_as_factor) {
      pl <- pl +
        ggplot2::geom_rug(data=bdat, sides = "t", ggplot2::aes(x = x, y=y), colour=vpc_theme$bin_separators_color)
    }
    pl <- pl + ggplot2::xlab(xlab) + ggplot2::ylab(ylab)
    if (log_x) {
      if(!idv_as_factor) pl <- pl + ggplot2::scale_x_log10()
      else warning("log_x option has no effect when the IDV is a factor ")
    }
    if (log_y) {
      pl <- pl + ggplot2::scale_y_log10()
    }
    if(!is.null(db$stratify)) {
      if(length(db$stratify) == 1) {
        if(is.null(db$labeller)) db$labeller <- ggplot2::label_both
        if (db$facet == "wrap") {
          pl <- pl + ggplot2::facet_wrap(stats::reformulate(db$stratify[1], NULL), 
                                         labeller = db$labeller)
        } else {
          if(length(grep("row", db$facet))>0) {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[1], NULL),
                                           labeller = db$labeller)
          } else {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(".", db$stratify[1]),
                                           labeller = db$labeller)
          }
        }
      } else { # 2 grid-stratification
        if (db$stratify[1] %in% c(colnames(db$vpc_dat), colnames(db$aggr_obs))) {
          if(length(grep("row", db$facet))>0) {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[1], db$stratify[2]),
                                           labeller = db$labeller)
          } else {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[2], db$stratify[1]),
                                           labeller = db$labeller)
          }
        } else { # only color stratification
          if ("strat" %in% c(colnames(db$vpc_dat), colnames(db$aggr_obs))) {
            # color stratification only
          } else {
            stop ("Stratification unsuccesful.")
          }
        }
      }
    }
    if(!is.null(db$lloq)) {
      pl <- pl + ggplot2::geom_hline(yintercept = db$lloq, colour=vpc_theme$loq_color) 
    }
    if(!is.null(db$uloq)) {
      pl <- pl + ggplot2::geom_hline(yintercept = db$uloq, colour=vpc_theme$loq_color)
    }
    if (!is.null(title)) {
      pl <- pl + ggplot2::ggtitle(title)
    }
    pl <- pl + theme_plain()
    return(pl)

  } else {

    ################################################################
    ## VPC for time-to-event data
    ################################################################

    show <- replace_list_elements(show_default_tte, show)
    if(!is.null(db$stratify_pars)) {
      ## rename "strat" to original stratification variable names
      if(length(db$stratify_pars) == 1) {
        # "strat1" ==> "rtte"
        if(!is.null(db$obs_km)) db$obs_km[[db$stratify_pars[1]]] <- as.factor(db$obs_km$strat)
        if(!is.null(db$sim_km)) db$sim_km[[db$stratify_pars[1]]] <- as.factor(db$sim_km$strat)
        if(!is.null(db$all)) db$all[[db$stratify_pars[1]]] <- as.factor(db$all$strat)
      }
      if(length(db$stratify_pars) == 2) {
        if(!is.null(db$obs_km)) {
          db$obs_km[[db$stratify_pars[1]]] <- as.factor(db$obs_km$strat1)
          db$obs_km[[db$stratify_pars[2]]] <- as.factor(db$obs_km$strat2)
        }
        if(!is.null(db$sim_km)) {
          db$sim_km[[db$stratify_pars[1]]] <- as.factor(db$sim_km$strat1)
          db$sim_km[[db$stratify_pars[2]]] <- as.factor(db$sim_km$strat2)
        }
      }
    }

    show$pi_as_area <- TRUE
    pl <- ggplot2::ggplot(db$sim_km, ggplot2::aes(x=bin_mid, y=qmed))
    if(show$sim_km) {
      db$all$strat_sim <- paste0(db$all$strat, "_", db$all$i)
      transp <- min(.1, 20*(1/length(unique(db$all$i))))
      pl <- pl + ggplot2::geom_step(data = db$all, ggplot2::aes(x=bin_mid, y=surv, group=strat_sim), colour=grDevices::rgb(0.2,.53,0.796, transp))
    }
    if(show$pi_as_area) {
      if(smooth) {
        if(!is.null(db$stratify_color)) {
          pl <- pl + ggplot2::geom_ribbon(data = db$sim_km, 
                                          ggplot2::aes(min = qmin, max=qmax, y=qmed, fill = get(db$stratify_color[1])), 
                                          alpha=vpc_theme$sim_median_alpha)
        } else {
          pl <- pl + ggplot2::geom_ribbon(data = db$sim_km, 
                                          ggplot2::aes(min = qmin, max=qmax, y=qmed), 
                                          fill = vpc_theme$sim_median_fill, 
                                          alpha=vpc_theme$sim_median_alpha)
        }
      } else {
        if(!is.null(db$stratify_color)) {
          pl <- pl + ggplot2::geom_rect(data = db$sim_km, 
                                      ggplot2::aes(xmin=bin_min, xmax=bin_max, ymin=qmin, ymax=qmax, fill = get(db$stratify_color[1])), 
                                      alpha=vpc_theme$sim_median_alpha)
        } else {
          pl <- pl + ggplot2::geom_rect(data = db$sim_km, 
                                        ggplot2::aes(xmin=bin_min, xmax=bin_max, ymin=qmin, ymax=qmax), 
                                        alpha=vpc_theme$sim_median_alpha, 
                                        fill = vpc_theme$sim_median_fill)
        }
      }
    } else {
      if(!is.null(db$obs)) {
        pl <- ggplot2::ggplot(db$obs_km)
      }
    }
    if(!is.null(db$cens_dat) && nrow(db$cens_dat)>0) {
      pl <- pl + ggplot2::geom_point(data=db$cens_dat, ggplot2::aes(x=time, y=y), shape="|", size=2.5)
    }
    if(show$sim_median) {
      if (smooth) {
        geom_line_custom <- ggplot2::geom_line
      } else {
        geom_line_custom <- ggplot2::geom_step
      }
      pl <- pl + geom_line_custom(linetype="dashed")
    }
    if(!is.null(db$obs) && show$obs_ci) {
      pl <- pl + ggplot2::geom_ribbon(
        data=db$obs_km, 
        ggplot2::aes(x=time, ymin=lower, ymax=upper, group=strat), 
        fill=vpc_theme$obs_ci_fill, colour = NA)
    }
    if (!is.null(db$obs) && show$obs_dv) {
      chk_tbl <- db$obs_km %>%
        dplyr::group_by(strat) %>%
        dplyr::summarise(t = length(time))
      if (sum(chk_tbl$t <= 1)>0) { # it is not safe to use geom_step, so use
        geom_step <- ggplot2::geom_line
      }
      msg("Warning: some strata in the observed data had zero or one observations, using line instead of step plot. Consider using less strata (e.g. using the 'events' argument).", verbose)
      if(!is.null(db$stratify_color)) {
        pl <- pl + ggplot2::geom_step(data = db$obs_km, 
                                      ggplot2::aes(x=time, y=surv, colour=get(db$stratify_color[1])), size=.8)
      } else {
        pl <- pl + ggplot2::geom_step(data = db$obs_km, 
                                      ggplot2::aes(x=time, y=surv, group=strat), size=.8)
      }
    }

    if(!is.null(db$stratify)) {
      if(is.null(db$labeller)) db$labeller <- ggplot2::label_both
      if (length(db$stratify_pars) == 1 | db$rtte) {
        if (db$facet == "wrap") {
          pl + ggplot2::facet_wrap(~sex)
          pl <- pl + ggplot2::facet_wrap(stats::reformulate(db$stratify[1], NULL),
                                         labeller = db$labeller)
        } else {
          if(length(grep("row", db$facet))>0) {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[1], NULL),
                                           labeller = db$labeller)
          } else {
            pl <- pl + ggplot2::facet_grid(stats::reformulate(".", db$stratify[1]),
                                           labeller = db$labeller)
          }
        }
      } else {
        if(length(grep("row", db$facet))>0) {
          pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[1], db$stratify[2]),
                                         labeller = db$labeller)
        } else {
          pl <- pl + ggplot2::facet_grid(stats::reformulate(db$stratify[2], db$stratify[1]),
                                         labeller = db$labeller)
        }
      }
    }
    if (show$bin_sep) {
      if(!(class(db$bins) == "logical" && db$bins == FALSE)) {
        bdat <- data.frame(cbind(x = db$tmp_bins, y = NA))
        pl <- pl + ggplot2::geom_rug(data=bdat, sides = "t", ggplot2::aes(x = x, y=y, group=NA), colour=vpc_theme$bin_separators_color)
      }
    }
    if(is.null(xlab)) {
      xlab <- "Time"
    }
    if(is.null(ylab)) {
      if(is.null(db$kmmc)) {
        if(db$as_percentage && is.null(db$kmmc)) {
          percent <- seq(from=0, to=100, by=25)
          pl <- pl +
            ggplot2::scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = percent)
          ylab <- "Survival (%)"
        } else {
          ylab <- "Survival"
        }
      } else {
        ylab <- paste0("Mean (", db$kmmc, ")")
      }
    }
    if(!is.null(db$stratify_color)) {
      pl <- pl + ggplot2::guides(fill = ggplot2::guide_legend(title=db$stratify_color[1]),
                                 colour = ggplot2::guide_legend(title=db$stratify_color[1]))
    }
    pl <- pl + ggplot2::xlab(xlab) + ggplot2::ylab(ylab)
    # pl <- pl + theme_plain()
    return(pl)
  }
}
