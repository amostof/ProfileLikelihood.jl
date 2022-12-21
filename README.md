# ProfileLikelihood 


[![DOI](https://zenodo.org/badge/508701126.svg)](https://zenodo.org/badge/latestdoi/508701126)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://DanielVandH.github.io/ProfileLikelihood.jl/dev)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://DanielVandH.github.io/ProfileLikelihood.jl/stable)

This package defines the routines required for computing maximum likelihood estimates and profile likelihoods. The optimisation routines are built around the [Optimization.jl](https://github.com/SciML/Optimization.jl) interface, allowing us to e.g. easily switch between algorithms, between finite differences and automatic differentiation, and it allows for constraints to be defined with ease. Below we list the definitions we are using for likelihoods and profile likelihoods. This code only works for scalar parameters of interest (i.e. out of a vector $\boldsymbol \theta$, you can profile a single scalar parameter $\theta_i \in \boldsymbol\theta$) for now.

**Definition: Likelihood function** (see Casella & Berger, 2002): Let $f(\boldsymbol x \mid \boldsymbol \theta)$ denote the joint probability density function (PDF) of the sample $\boldsymbol X = (X_1,\ldots,X_n)^{\mathsf T}$, where $\boldsymbol \theta \in \Theta$ is some set of parameters and $\Theta$ is the parameter space. We define the _likelihood function_ $\mathcal L \colon \Theta \to [0, \infty)$ by $\mathcal L(\boldsymbol \theta \mid \boldsymbol x) = f(\boldsymbol x \mid \boldsymbol \theta)$ for some realisation $\boldsymbol x = (x_1,\ldots,x_n)^{\mathsf T}$ of $\boldsymbol X$. The _log-likelihood function_ $\ell\colon\Theta\to\mathbb R$ is defined by $\ell(\boldsymbol \theta \mid \boldsymbol x) =  \log\mathcal L(\boldsymbol\theta \mid \boldsymbol x)$.The _maximum likelihood estimate_ (MLE) $\hat{\boldsymbol\theta}$ is the parameter $\boldsymbol\theta$ that maximises the likelihood function, $\hat{\boldsymbol{\theta}} = argmax_{\boldsymbol{\theta} \in \Theta} \mathcal{L}(\boldsymbol{\theta} \mid \boldsymbol x) = argmax_{\boldsymbol\theta \in \Theta} \ell(\boldsymbol\theta \mid \boldsymbol x)$.

**Definition: Profile likelihood function** (see Pawitan, 2001): Suppose we have some parameters of interest, $\boldsymbol \theta \in \Theta$, and some nuisance parameters, $\boldsymbol \phi \in \Phi$, and some data $\boldsymbol x = (x_1,\ldots,x_n)^{\mathsf T}$, giving some joint likelihood $\mathcal L \colon \Theta \cup \Phi \to [0, \infty)$ defined by $\mathcal L(\boldsymbol\theta, \boldsymbol\phi \mid \boldsymbol x)$. We define the _profile likelihood_ $\mathcal L_p \colon \Theta \to [0, \infty)$ of $\boldsymbol\theta$ by $\mathcal L_p(\boldsymbol\theta \mid \boldsymbol x) = \sup_{\boldsymbol \phi \in \Phi \mid \boldsymbol \theta} \mathcal L(\boldsymbol \theta, \boldsymbol \phi \mid \boldsymbol x)$. The _profile log-likelihood_ $\ell_p \colon \Theta \to \mathbb R$ of $\boldsymbol\theta$ is defined by $\ell_p(\boldsymbol \theta \mid \boldsymbol x) = \log \mathcal L_p(\boldsymbol\theta \mid \boldsymbol x)$. The _normalised profile likelihood_ is defined by $\hat{\mathcal L}_p(\boldsymbol\theta \mid \boldsymbol x) = \mathcal L_p(\boldsymbol \theta \mid \boldsymbol x) - \mathcal L_p(\hat{\boldsymbol\theta} \mid \boldsymbol x)$, where $\hat{\boldsymbol\theta}$ is the MLE of $\boldsymbol\theta$, and similarly for the normalised profile log-likelihood.

From Wilk's theorem, we know that $2\hat{\ell}\_p(\boldsymbol\theta \mid \boldsymbol x) \geq -\chi_{p, 1-\alpha}^2$ is an approximate $100(1-\alpha)\%$ confidence region for $\boldsymbol \theta$, and this enables us to obtain confidence intervals for parameters by considering only their profile likelihood, where $\chi_{p,1-\alpha}^2$ is the $1-\alpha$ quantile of the $\chi_p^2$ distribution and $p$ is the length of $\boldsymbol\theta$. For the case of a scalar parameter of interest, $-\chi_{1, 0.95}^2 \approx -1.92$.

We compute the profile log-likelihood in this package by starting at the MLE, and stepping left/right until we reach a given threshold. The code is iterative to not waste time in so much of the parameter space.

More detail about the methods we use in this package are given in the documentation, along with several examples.
