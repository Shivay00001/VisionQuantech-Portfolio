import { Check } from 'lucide-react';
import Link from 'next/link';

export default function PricingPage() {
  return (
    <div className="container mx-auto px-4 py-16">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h1 className="text-4xl font-bold mb-4">Simple, Transparent Pricing</h1>
          <p className="text-xl text-gray-600">
            Choose the plan that fits your needs. Upgrade or downgrade anytime.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {/* Free Plan */}
          <PricingCard
            name="Free"
            price="$0"
            period="forever"
            description="Perfect for trying out our tools"
            features={[
              '10 jobs per day',
              '10MB max file size',
              '5 files per job',
              'Core PDF tools',
              'Basic conversions',
              'Community support',
            ]}
            cta="Get Started"
            ctaHref="/auth/signup"
            popular={false}
          />

          {/* Pro Plan */}
          <PricingCard
            name="Pro"
            price="$19"
            period="per month"
            description="For professionals and power users"
            features={[
              '500 jobs per day',
              '100MB max file size',
              '25 files per job',
              'All core tools',
              'AI-powered features',
              'Advanced conversions',
              'Watermarks & page numbers',
              'Priority support',
              'No ads',
            ]}
            cta="Start Pro Trial"
            ctaHref="/auth/signup?plan=pro"
            popular={true}
          />

          {/* Business Plan */}
          <PricingCard
            name="Business"
            price="$99"
            period="per month"
            description="For teams and enterprises"
            features={[
              '5,000 jobs per day',
              '500MB max file size',
              '100 files per job',
              'Everything in Pro',
              'Resume analyzer',
              'Invoice & contract parser',
              'Quiz & flashcard generator',
              'API access',
              'Team management',
              'Dedicated support',
              'Custom integrations',
            ]}
            cta="Contact Sales"
            ctaHref="/contact"
            popular={false}
          />
        </div>

        {/* FAQ Section */}
        <div className="mt-20">
          <h2 className="text-3xl font-bold text-center mb-12">
            Frequently Asked Questions
          </h2>
          <div className="max-w-3xl mx-auto space-y-6">
            <FAQItem
              question="Can I change my plan later?"
              answer="Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately."
            />
            <FAQItem
              question="What payment methods do you accept?"
              answer="We accept all major credit cards (Visa, Mastercard, American Express) via Stripe."
            />
            <FAQItem
              question="Is there a free trial for paid plans?"
              answer="Yes! Pro plan comes with a 14-day free trial. No credit card required."
            />
            <FAQItem
              question="What happens to my files?"
              answer="All files are automatically deleted after 1 hour for security. We never store your documents permanently."
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function PricingCard({
  name,
  price,
  period,
  description,
  features,
  cta,
  ctaHref,
  popular,
}: any) {
  return (
    <div
      className={`relative bg-white rounded-2xl border-2 p-8 ${
        popular ? 'border-blue-600 shadow-xl' : 'border-gray-200'
      }`}
    >
      {popular && (
        <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-blue-600 text-white px-4 py-1 rounded-full text-sm font-semibold">
          Most Popular
        </div>
      )}

      <div className="mb-6">
        <h3 className="text-2xl font-bold mb-2">{name}</h3>
        <div className="flex items-baseline gap-1 mb-2">
          <span className="text-4xl font-bold">{price}</span>
          <span className="text-gray-600">/ {period}</span>
        </div>
        <p className="text-gray-600">{description}</p>
      </div>

      <ul className="space-y-3 mb-8">
        {features.map((feature: string, i: number) => (
          <li key={i} className="flex items-start gap-3">
            <Check className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
            <span className="text-gray-700">{feature}</span>
          </li>
        ))}
      </ul>

      <Link
        href={ctaHref}
        className={`block w-full py-3 rounded-lg font-semibold text-center transition ${
          popular
            ? 'bg-blue-600 text-white hover:bg-blue-700'
            : 'bg-gray-100 text-gray-900 hover:bg-gray-200'
        }`}
      >
        {cta}
      </Link>
    </div>
  );
}

function FAQItem({ question, answer }: any) {
  return (
    <div className="border-b border-gray-200 pb-6">
      <h3 className="text-lg font-semibold mb-2">{question}</h3>
      <p className="text-gray-600">{answer}</p>
    </div>
  );
}