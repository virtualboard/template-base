# Generate Component Story (GCS)

**Trigger Phrases:**
- "Generate Component Story"
- "GCS"
- "Create Storybook story"
- "Add story"

**Action:**
When the Frontend Developer agent receives this command, it should:

## 1. Gather Requirements
- Component to document
- Framework (React/Vue/Angular/Svelte)
- Existing Storybook configuration
- Component variants/states to showcase
- Interactive controls needed

### 2. Check Storybook Setup
Verify Storybook is configured, or guide installation:

```bash
# Initialize Storybook (if not present)
npx storybook@latest init

# For React
npx storybook@latest init --type react

# For Vue
npx storybook@latest init --type vue3

# For Angular
npx storybook@latest init --type angular
```

### 3. Create Component Story
Generate story file based on framework:

**File Location:**
```
src/components/{ComponentName}/{ComponentName}.stories.tsx
# or
src/stories/{ComponentName}.stories.tsx
```

**React + TypeScript Story (CSF 3.0):**
```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from './ComponentName';

/**
 * ComponentName is used for [purpose description].
 *
 * ## Usage
 * ```tsx
 * <ComponentName prop1="value" prop2={true} />
 * ```
 */
const meta = {
  title: 'Components/ComponentName',
  component: ComponentName,
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'Detailed description of the component and its purpose.',
      },
    },
  },
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'tertiary'],
      description: 'Visual variant of the component',
    },
    size: {
      control: 'radio',
      options: ['small', 'medium', 'large'],
      description: 'Size of the component',
    },
    disabled: {
      control: 'boolean',
      description: 'Disable the component',
    },
    onClick: { action: 'clicked' },
  },
} satisfies Meta<typeof ComponentName>;

export default meta;
type Story = StoryObj<typeof meta>;

/**
 * Default state of the component
 */
export const Default: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    children: 'Button Text',
  },
};

/**
 * Primary variant with large size
 */
export const Primary: Story = {
  args: {
    variant: 'primary',
    size: 'large',
    children: 'Primary Button',
  },
};

/**
 * Secondary variant
 */
export const Secondary: Story = {
  args: {
    variant: 'secondary',
    size: 'medium',
    children: 'Secondary Button',
  },
};

/**
 * Disabled state
 */
export const Disabled: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    disabled: true,
    children: 'Disabled Button',
  },
};

/**
 * All size variants
 */
export const Sizes: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
      <ComponentName size="small">Small</ComponentName>
      <ComponentName size="medium">Medium</ComponentName>
      <ComponentName size="large">Large</ComponentName>
    </div>
  ),
};

/**
 * All variants
 */
export const Variants: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: '1rem' }}>
      <ComponentName variant="primary">Primary</ComponentName>
      <ComponentName variant="secondary">Secondary</ComponentName>
      <ComponentName variant="tertiary">Tertiary</ComponentName>
    </div>
  ),
};

/**
 * With custom styling
 */
export const CustomStyle: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    children: 'Custom Styled',
    style: { borderRadius: '20px' },
  },
};

/**
 * Loading state (if applicable)
 */
export const Loading: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    loading: true,
    children: 'Loading...',
  },
};
```

**Vue 3 + TypeScript Story:**
```typescript
import type { Meta, StoryObj } from '@storybook/vue3';
import ComponentName from './ComponentName.vue';

const meta = {
  title: 'Components/ComponentName',
  component: ComponentName,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'tertiary'],
    },
    size: {
      control: 'radio',
      options: ['small', 'medium', 'large'],
    },
    onClick: { action: 'clicked' },
  },
} satisfies Meta<typeof ComponentName>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
  },
  render: (args) => ({
    components: { ComponentName },
    setup() {
      return { args };
    },
    template: '<ComponentName v-bind="args">Button Text</ComponentName>',
  }),
};

export const Primary: Story = {
  args: {
    variant: 'primary',
    size: 'large',
  },
};

export const AllVariants: Story = {
  render: () => ({
    components: { ComponentName },
    template: `
      <div style="display: flex; gap: 1rem;">
        <ComponentName variant="primary">Primary</ComponentName>
        <ComponentName variant="secondary">Secondary</ComponentName>
        <ComponentName variant="tertiary">Tertiary</ComponentName>
      </div>
    `,
  }),
};
```

**Angular Story:**
```typescript
import type { Meta, StoryObj } from '@storybook/angular';
import { ComponentNameComponent } from './component-name.component';

const meta: Meta<ComponentNameComponent> = {
  title: 'Components/ComponentName',
  component: ComponentNameComponent,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'tertiary'],
    },
    size: {
      control: 'radio',
      options: ['small', 'medium', 'large'],
    },
    onClick: { action: 'clicked' },
  },
};

export default meta;
type Story = StoryObj<ComponentNameComponent>;

export const Default: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    text: 'Button Text',
  },
};

export const Primary: Story = {
  args: {
    variant: 'primary',
    size: 'large',
    text: 'Primary Button',
  },
};

export const Disabled: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
    disabled: true,
    text: 'Disabled Button',
  },
};
```

**Svelte Story:**
```typescript
import type { Meta, StoryObj } from '@storybook/svelte';
import ComponentName from './ComponentName.svelte';

const meta = {
  title: 'Components/ComponentName',
  component: ComponentName,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'tertiary'],
    },
    size: {
      control: 'radio',
      options: ['small', 'medium', 'large'],
    },
  },
} satisfies Meta<ComponentName>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    variant: 'primary',
    size: 'medium',
  },
};

export const Primary: Story = {
  args: {
    variant: 'primary',
    size: 'large',
  },
};
```

### 4. Add Advanced Story Features

**With Decorators:**
```typescript
export const WithThemeProvider: Story = {
  args: {
    variant: 'primary',
  },
  decorators: [
    (Story) => (
      <ThemeProvider theme={defaultTheme}>
        <Story />
      </ThemeProvider>
    ),
  ],
};
```

**With Play Function (Interactions):**
```typescript
import { within, userEvent, expect } from '@storybook/test';

export const Interactive: Story = {
  args: {
    variant: 'primary',
    children: 'Click Me',
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');

    await userEvent.click(button);
    await expect(button).toHaveClass('clicked');
  },
};
```

**With Custom Docs:**
```typescript
export const Documented: Story = {
  args: {
    variant: 'primary',
  },
  parameters: {
    docs: {
      description: {
        story: 'This story demonstrates the primary variant with custom documentation.',
      },
      source: {
        code: `<ComponentName variant="primary">Custom Text</ComponentName>`,
      },
    },
  },
};
```

**With Multiple Components:**
```typescript
export const Composition: Story = {
  render: () => (
    <Card>
      <CardHeader>
        <ComponentName variant="primary">Header Button</ComponentName>
      </CardHeader>
      <CardBody>
        <p>Content goes here</p>
      </CardBody>
      <CardFooter>
        <ComponentName variant="secondary">Cancel</ComponentName>
        <ComponentName variant="primary">Confirm</ComponentName>
      </CardFooter>
    </Card>
  ),
};
```

### 5. Add Documentation Annotations

Include MDX documentation if needed:

**ComponentName.stories.mdx:**
```mdx
import { Meta, Canvas, Story, ArgsTable } from '@storybook/blocks';
import * as ComponentStories from './ComponentName.stories';

<Meta of={ComponentStories} />

# ComponentName

ComponentName is a versatile component for [purpose].

## Usage

<Canvas of={ComponentStories.Default} />

## Props

<ArgsTable of={ComponentStories} />

## Variants

<Canvas of={ComponentStories.Variants} />

## Accessibility

This component follows WCAG 2.1 AA guidelines:
- Keyboard navigable
- Screen reader friendly
- Sufficient color contrast
- Focus indicators

## Best Practices

- Use `variant="primary"` for main actions
- Use `variant="secondary"` for auxiliary actions
- Always provide meaningful text content
- Consider loading states for async actions
```

### 6. Configure Story Parameters

Add story-specific configuration:

```typescript
export const ResponsiveExample: Story = {
  args: {
    variant: 'primary',
  },
  parameters: {
    viewport: {
      defaultViewport: 'mobile1',
    },
    backgrounds: {
      default: 'dark',
    },
    layout: 'fullscreen',
  },
};
```

### 7. Update Storybook Configuration
If needed, update `.storybook/main.ts`:

```typescript
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  stories: [
    '../src/**/*.mdx',
    '../src/**/*.stories.@(js|jsx|ts|tsx)',
  ],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
    '@storybook/addon-a11y', // Accessibility testing
  ],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
};

export default config;
```

### 8. Announce Completion
- Show story file path created
- Provide Storybook URL (typically `http://localhost:6006`)
- List all story variants created
- Mention available controls and interactions
- Suggest running `npm run storybook` to view stories
