/**
 * STRUCTURAL TEMPLATE ONLY — all colors, fonts, radii, icons, and copy MUST
 * come from the project DESIGN.md; do not ship this file's neutral styling
 * as the design.
 *
 * Structure notes:
 * - Hero is a thesis: headline-led, left-aligned, no decorative gradients,
 *   blobs, eyebrow pills, or fake social proof.
 * - Features use varied composition (alternating media/text), never an
 *   identical icon-card row (the #1 AI tell — see design-craft/AVOID-LIST.md).
 * - The DESIGN.md signature element belongs in the hero or the flagship
 *   feature block — one bold move, everything else quiet.
 */
"use client";

import { ArrowRight, Check } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  PageTransition,
  StaggerContainer,
  StaggerItem,
  FadeInUp,
} from "@/components/motion";
import { AnimatedCard, CTAButton } from "@/components/interactive";

// ============================================
// HERO SECTION — headline as thesis
// ============================================
export function HeroSection() {
  return (
    <section className="py-20 md:py-32 border-b">
      <div className="container">
        <div className="max-w-3xl">
          {/* Headline leads. Copy states what the product concretely does. */}
          <FadeInUp>
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-semibold tracking-tight mb-6">
              State the product&apos;s core promise in one concrete sentence
            </h1>
          </FadeInUp>

          <FadeInUp delay={0.1}>
            <p className="text-lg md:text-xl text-muted-foreground mb-8 max-w-2xl">
              One supporting sentence: who it is for and what job it does.
              No buzzwords — say what actually happens.
            </p>
          </FadeInUp>

          <FadeInUp delay={0.2}>
            <div className="flex flex-col sm:flex-row gap-4">
              {/* Buttons say exactly what happens (DESIGN.md copy voice) */}
              <CTAButton size="lg">
                Create your first project
                <ArrowRight className="h-4 w-4" />
              </CTAButton>
              <Button variant="outline" size="lg">
                See how it works
              </Button>
            </div>
          </FadeInUp>
        </div>
      </div>
    </section>
  );
}

// ============================================
// FEATURES — alternating media/text rows,
// NOT an identical icon-card grid
// ============================================
interface FeatureRow {
  title: string;
  description: string;
  bullets: string[];
}

export function FeaturesSection() {
  const features: FeatureRow[] = [
    {
      title: "Name the first capability plainly",
      description:
        "Two sentences on what the user can now do and why it matters to their real work.",
      bullets: ["Concrete outcome one", "Concrete outcome two"],
    },
    {
      title: "Name the second capability plainly",
      description:
        "Describe the workflow it replaces or the time it saves — specifics, not adjectives.",
      bullets: ["Concrete outcome one", "Concrete outcome two"],
    },
  ];

  return (
    <section className="py-20 md:py-32">
      <div className="container space-y-20 md:space-y-28">
        {features.map((feature, index) => (
          <FadeInUp key={feature.title}>
            <div
              className={`grid gap-8 md:gap-16 md:grid-cols-2 items-center ${
                index % 2 === 1 ? "md:[&>*:first-child]:order-2" : ""
              }`}
            >
              {/* Text column — heading leads, no icon tile above it */}
              <div>
                <h2 className="text-2xl md:text-3xl font-semibold tracking-tight mb-4">
                  {feature.title}
                </h2>
                <p className="text-muted-foreground mb-6">
                  {feature.description}
                </p>
                <ul className="space-y-3">
                  {feature.bullets.map((bullet) => (
                    <li key={bullet} className="flex items-center gap-2 text-sm">
                      <Check className="h-4 w-4 text-primary flex-shrink-0" />
                      {bullet}
                    </li>
                  ))}
                </ul>
              </div>

              {/* Media column — replace with a real product screenshot or
                  the DESIGN.md signature treatment. Never leave as a gray box. */}
              <div className="aspect-video rounded-lg border bg-muted" />
            </div>
          </FadeInUp>
        ))}
      </div>
    </section>
  );
}

// ============================================
// PRICING SECTION
// ============================================
export function PricingSection() {
  const plans = [
    {
      name: "Starter",
      price: "Free",
      description: "Perfect for getting started",
      features: ["Up to 3 projects", "Basic analytics", "Email support"],
      cta: "Start free",
      popular: false,
    },
    {
      name: "Pro",
      price: "$29",
      period: "/month",
      description: "For growing teams",
      features: [
        "Unlimited projects",
        "Advanced analytics",
        "Priority support",
        "Custom integrations",
      ],
      cta: "Start 14-day trial",
      popular: true,
    },
    {
      name: "Enterprise",
      price: "Custom",
      description: "For large organizations",
      features: [
        "Everything in Pro",
        "Dedicated support",
        "SLA guarantee",
        "Custom contracts",
      ],
      cta: "Contact sales",
      popular: false,
    },
  ];

  return (
    <section className="py-20 md:py-32 bg-muted/30 border-y">
      <div className="container">
        <FadeInUp className="max-w-2xl mb-16">
          <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
            Simple, transparent pricing
          </h2>
          <p className="text-muted-foreground">
            Choose the plan that works best for you. No hidden fees.
          </p>
        </FadeInUp>

        <StaggerContainer className="grid md:grid-cols-3 gap-6 md:gap-8 max-w-5xl">
          {plans.map((plan) => (
            <StaggerItem key={plan.name}>
              <AnimatedCard
                className={`h-full flex flex-col ${
                  plan.popular ? "border-primary ring-2 ring-primary" : ""
                }`}
              >
                {plan.popular && (
                  <div className="bg-primary text-primary-foreground text-xs font-medium px-3 py-1 rounded-full self-start mb-4">
                    Most popular
                  </div>
                )}
                <h3 className="text-lg font-semibold">{plan.name}</h3>
                <div className="mt-2 mb-4">
                  <span className="text-3xl font-semibold tabular-nums">
                    {plan.price}
                  </span>
                  {plan.period && (
                    <span className="text-muted-foreground">{plan.period}</span>
                  )}
                </div>
                <p className="text-sm text-muted-foreground mb-6">
                  {plan.description}
                </p>
                <ul className="space-y-3 mb-8 flex-1">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-center gap-2 text-sm">
                      <Check className="h-4 w-4 text-primary flex-shrink-0" />
                      {feature}
                    </li>
                  ))}
                </ul>
                <Button
                  className="w-full"
                  variant={plan.popular ? "default" : "outline"}
                >
                  {plan.cta}
                </Button>
              </AnimatedCard>
            </StaggerItem>
          ))}
        </StaggerContainer>
      </div>
    </section>
  );
}

// ============================================
// CTA SECTION
// ============================================
export function CTASection() {
  return (
    <section className="py-20 md:py-32">
      <div className="container">
        <FadeInUp>
          <div className="max-w-3xl">
            <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
              Ready to get started?
            </h2>
            <p className="text-muted-foreground mb-8 max-w-2xl">
              Close with the same concrete promise as the hero — what the user
              will have after signing up, not how it will feel.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Button size="lg">
                Create your first project
                <ArrowRight className="h-4 w-4 ml-2" />
              </Button>
              <Button size="lg" variant="outline">
                Talk to sales
              </Button>
            </div>
          </div>
        </FadeInUp>
      </div>
    </section>
  );
}

// ============================================
// FULL LANDING PAGE
// ============================================
export default function LandingPage() {
  return (
    <PageTransition>
      <HeroSection />
      <FeaturesSection />
      <PricingSection />
      <CTASection />
    </PageTransition>
  );
}
